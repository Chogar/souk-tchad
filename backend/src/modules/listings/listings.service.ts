import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Category } from '../../entities/category.entity';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Listing, ListingStatus } from '../../entities/listing.entity';
import { User } from '../../entities/user.entity';
import { CategoriesService } from '../categories/categories.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { ModerationService } from './moderation.service';

@Injectable()
export class ListingsService {
  constructor(
    @InjectRepository(Listing)
    private readonly listingsRepository: Repository<Listing>,
    private readonly categoriesService: CategoriesService,
    private readonly moderationService: ModerationService,
    private readonly subscriptionsService: SubscriptionsService,
  ) {}

  async findAll(filters?: {
    categoryId?: string;
    search?: string;
    city?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(filters?.page ?? 1, 1);
    const limit = Math.min(Math.max(filters?.limit ?? 50, 1), 100);

    const qb = this.listingsRepository
      .createQueryBuilder('listing')
      .leftJoinAndSelect('listing.category', 'category')
      .leftJoinAndSelect('listing.user', 'user')
      .where('listing.status = :status', { status: ListingStatus.ACTIVE })
      .orderBy('listing.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (filters?.categoryId) {
      qb.andWhere('listing.categoryId = :categoryId', {
        categoryId: filters.categoryId,
      });
    }

    if (filters?.city) {
      qb.andWhere('listing.city ILIKE :city', { city: `%${filters.city}%` });
    }

    if (filters?.search) {
      const terms = filters.search
        .trim()
        .split(/\s+/)
        .filter((term) => term.length > 1);

      if (terms.length === 1) {
        qb.andWhere(
          '(listing.title ILIKE :search OR listing.description ILIKE :search)',
          { search: `%${terms[0]}%` },
        );
      } else if (terms.length > 1) {
        const clauses = terms.map(
          (_, index) =>
            `(listing.title ILIKE :term${index} OR listing.description ILIKE :term${index})`,
        );
        const params = Object.fromEntries(
          terms.map((term, index) => [`term${index}`, `%${term}%`]),
        );
        qb.andWhere(`(${clauses.join(' OR ')})`, params);
      }
    }

    const listings = await qb.getMany();
    return listings.map((listing) => this.toPublicListing(listing));
  }

  async findById(id: string) {
    const listing = await this.findByIdWithRelations(id);
    return this.toPublicListing(listing);
  }

  async findByUser(userId: string) {
    const listings = await this.listingsRepository.find({
      where: { userId },
      relations: { category: true, user: true },
      order: { createdAt: 'DESC' },
    });
    return listings.map((listing) => this.toPublicListing(listing));
  }

  private async findByIdWithRelations(id: string): Promise<Listing> {
    const listing = await this.listingsRepository.findOne({
      where: { id },
      relations: { category: true, user: true },
    });
    if (!listing) {
      throw new NotFoundException('Annonce introuvable');
    }
    return listing;
  }

  async create(user: User, dto: CreateListingDto, images: string[] = []) {
    await this.ensureCanCreateListing(user);

    const category = await this.categoriesService.findById(dto.categoryId);
    if (!category) {
      throw new NotFoundException('Catégorie introuvable');
    }

    const customCategoryName = this.resolveCustomCategoryName(
      category,
      dto.customCategoryName,
    );

    const moderation = this.moderationService.moderateListing({
      title: dto.title,
      description: dto.description,
      price: dto.price,
      categorySlug: category.slug,
    });

    const listing = this.listingsRepository.create({
      ...dto,
      customCategoryName,
      userId: user.id,
      images,
      status: moderation.status,
      city: dto.city ?? "N'Djamena",
      currency: dto.currency ?? 'XAF',
    });

    const saved = await this.listingsRepository.save(listing);
    return this.toPublicListing(await this.findByIdWithRelations(saved.id));
  }

  async update(user: User, id: string, dto: UpdateListingDto) {
    const listing = await this.findByIdWithRelations(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }

    const { images, videos, customCategoryName, ...fields } = dto;
    Object.assign(listing, fields);

    if (dto.categoryId || customCategoryName !== undefined) {
      const category = await this.categoriesService.findById(
        dto.categoryId ?? listing.categoryId,
      );
      if (!category) {
        throw new NotFoundException('Catégorie introuvable');
      }
      listing.customCategoryName = this.resolveCustomCategoryName(
        category,
        customCategoryName ?? listing.customCategoryName ?? undefined,
      );
    }

    if (images !== undefined) {
      // N’accepter que des chemins d’uploads listings appartenant au préfixe attendu.
      listing.images = images
        .filter((path) => typeof path === 'string' && path.startsWith('/uploads/listings/'))
        .slice(0, 5);
    }

    if (videos !== undefined) {
      listing.videos = videos
        .filter(
          (path) =>
            typeof path === 'string' &&
            path.startsWith('/uploads/listings/videos/'),
        )
        .slice(0, 1);
    }

    if (dto.title || dto.description || dto.price || dto.categoryId) {
      const category = await this.categoriesService.findById(
        dto.categoryId ?? listing.categoryId,
      );
      if (!category) {
        throw new NotFoundException('Catégorie introuvable');
      }

      const moderation = this.moderationService.moderateListing({
        title: listing.title,
        description: listing.description,
        price: Number(listing.price),
        categorySlug: category.slug,
      });
      listing.status = moderation.status;
    }

    const saved = await this.listingsRepository.save(listing);
    return this.toPublicListing(await this.findByIdWithRelations(saved.id));
  }

  async addImages(user: User, id: string, imagePaths: string[]) {
    const listing = await this.findByIdWithRelations(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }

    listing.images = [...listing.images, ...imagePaths].slice(0, 5);
    const saved = await this.listingsRepository.save(listing);
    return this.toPublicListing(await this.findByIdWithRelations(saved.id));
  }

  async addVideo(user: User, id: string, videoPath: string) {
    const listing = await this.findByIdWithRelations(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }

    listing.videos = [videoPath];
    const saved = await this.listingsRepository.save(listing);
    return this.toPublicListing(await this.findByIdWithRelations(saved.id));
  }

  async remove(user: User, id: string): Promise<void> {
    const listing = await this.findByIdWithRelations(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }
    await this.listingsRepository.remove(listing);
  }

  /** Masque e-mail / googleId du vendeur sur les réponses publiques. */
  private toPublicListing(listing: Listing) {
    const { user, ...rest } = listing;
    return {
      ...rest,
      user: user
        ? {
            id: user.id,
            name: user.name,
            avatarUrl: user.avatarUrl,
            phone: user.phone,
            plan: user.plan,
            isEmailVerified: user.isEmailVerified,
          }
        : undefined,
    };
  }

  private resolveCustomCategoryName(
    category: Category,
    customCategoryName?: string,
  ): string | null {
    if (category.slug !== 'autre') {
      return null;
    }

    const name = customCategoryName?.trim();
    if (!name || name.length < 2) {
      return 'Divers';
    }

    return name.slice(0, 80);
  }

  private async ensureCanCreateListing(user: User) {
    const max = this.subscriptionsService.getMaxListings(user.plan);
    if (max === -1) return;

    const activeCount = await this.listingsRepository.count({
      where: {
        userId: user.id,
        status: ListingStatus.ACTIVE,
      },
    });

    if (activeCount >= max) {
      throw new ForbiddenException(
        `Limite atteinte : ${max} annonces actives pour votre plan`,
      );
    }
  }
}
