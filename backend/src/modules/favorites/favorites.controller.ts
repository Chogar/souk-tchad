import {
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { User } from '../../entities/user.entity';
import { FavoritesService } from './favorites.service';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  findAll(@CurrentUser() user: User) {
    return this.favoritesService.findByUser(user.id);
  }

  @Get(':listingId/check')
  check(@CurrentUser() user: User, @Param('listingId') listingId: string) {
    return this.favoritesService.isFavorite(user.id, listingId);
  }

  @Post(':listingId')
  add(@CurrentUser() user: User, @Param('listingId') listingId: string) {
    return this.favoritesService.add(user.id, listingId);
  }

  @Delete(':listingId')
  remove(@CurrentUser() user: User, @Param('listingId') listingId: string) {
    return this.favoritesService.remove(user.id, listingId);
  }
}
