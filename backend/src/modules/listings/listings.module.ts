import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Listing } from '../../entities/listing.entity';
import { CategoriesModule } from '../categories/categories.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { ListingsController } from './listings.controller';
import { ListingsService } from './listings.service';
import { ModerationService } from './moderation.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Listing]),
    CategoriesModule,
    SubscriptionsModule,
  ],
  controllers: [ListingsController],
  providers: [ListingsService, ModerationService],
})
export class ListingsModule {}
