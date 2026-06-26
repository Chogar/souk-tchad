import {
  BadRequestException,
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
  }) {
    const qb = this.listingsRepository
      .createQueryBuilder('listing')
      .leftJoinAndSelect('listing.category', 'category')
      .leftJoinAndSelect('listing.user', 'user')
      .where('listing.status = :status', { status: ListingStatus.ACTIVE })
      .orderBy('listing.createdAt', 'DESC');

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

    return qb.getMany();
  }

  async findById(id: string): Promise<Listing> {
    const listing = await this.findByIdWithRelations(id);
    return listing;
  }

  async findByUser(userId: string): Promise<Listing[]> {
    return this.listingsRepository.find({
      where: { userId },
      relations: { category: true, user: true },
      order: { createdAt: 'DESC' },
    });
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
    return this.findByIdWithRelations(saved.id);
  }

  async update(user: User, id: string, dto: UpdateListingDto) {
    const listing = await this.findById(id);
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
      listing.images = images.slice(0, 5);
    }

    if (videos !== undefined) {
      listing.videos = videos.slice(0, 1);
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
    return this.findByIdWithRelations(saved.id);
  }

  async addImages(user: User, id: string, imagePaths: string[]) {
    const listing = await this.findById(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }

    listing.images = [...listing.images, ...imagePaths].slice(0, 5);
    const saved = await this.listingsRepository.save(listing);
    return this.findByIdWithRelations(saved.id);
  }

  async addVideo(user: User, id: string, videoPath: string) {
    const listing = await this.findById(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }

    listing.videos = [videoPath];
    const saved = await this.listingsRepository.save(listing);
    return this.findByIdWithRelations(saved.id);
  }

  async remove(user: User, id: string): Promise<void> {
    const listing = await this.findById(id);
    if (listing.userId !== user.id) {
      throw new ForbiddenException('Accès refusé');
    }
    await this.listingsRepository.remove(listing);
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
      throw new BadRequestException(
        'Indiquez une catégorie personnalisée (minimum 2 caractères).',
      );
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
