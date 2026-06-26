import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { User } from '../../entities/user.entity';
import { UsersService } from '../users/users.service';
import { SubscribeDto } from './dto/subscribe.dto';
import { SubscriptionsService } from './subscriptions.service';

@Controller('subscriptions')
export class SubscriptionsController {
  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly usersService: UsersService,
  ) {}

  @Get('plans')
  getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @Post('subscribe')
  @UseGuards(JwtAuthGuard)
  async subscribe(@CurrentUser() user: User, @Body() dto: SubscribeDto) {
    const updated = await this.subscriptionsService.subscribe(
      user.id,
      dto.plan,
    );
    return this.usersService.toPublic(updated);
  }
}
