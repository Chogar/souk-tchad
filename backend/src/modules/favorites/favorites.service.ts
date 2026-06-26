import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Favorite } from '../../entities/favorite.entity';
import { Listing } from '../../entities/listing.entity';

@Injectable()
export class FavoritesService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoritesRepository: Repository<Favorite>,
    @InjectRepository(Listing)
    private readonly listingsRepository: Repository<Listing>,
  ) {}

  async findByUser(userId: string): Promise<Favorite[]> {
    return this.favoritesRepository.find({
      where: { userId },
      relations: { listing: { category: true, user: true } },
      order: { createdAt: 'DESC' },
    });
  }

  async add(userId: string, listingId: string): Promise<Favorite> {
    const listing = await this.listingsRepository.findOne({
      where: { id: listingId },
    });
    if (!listing) {
      throw new NotFoundException('Annonce introuvable');
    }

    const existing = await this.favoritesRepository.findOne({
      where: { userId, listingId },
    });
    if (existing) {
      throw new ConflictException('Déjà en favoris');
    }

    const favorite = this.favoritesRepository.create({ userId, listingId });
    return this.favoritesRepository.save(favorite);
  }

  async remove(userId: string, listingId: string): Promise<void> {
    const favorite = await this.favoritesRepository.findOne({
      where: { userId, listingId },
    });
    if (!favorite) {
      throw new NotFoundException('Favori introuvable');
    }
    await this.favoritesRepository.remove(favorite);
  }

  async isFavorite(userId: string, listingId: string): Promise<boolean> {
    const count = await this.favoritesRepository.count({
      where: { userId, listingId },
    });
    return count > 0;
  }
}
