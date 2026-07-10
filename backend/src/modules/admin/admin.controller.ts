import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsEnum } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AdminGuard } from '../../common/guards/admin.guard';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ListingStatus } from '../../entities/listing.entity';
import { PaymentOrderStatus } from '../../entities/payment-order.entity';
import { User, UserRole } from '../../entities/user.entity';
import { UsersService } from '../users/users.service';
import { PaymentSettingsService } from '../payment-settings/payment-settings.service';
import { UpdatePaymentSettingsDto } from '../payment-settings/dto/update-payment-settings.dto';
import { AdminService } from './admin.service';

class UpdateListingStatusDto {
  @IsEnum(ListingStatus)
  status: ListingStatus;
}

class SetRoleDto {
  @IsEnum(UserRole)
  role: UserRole;
}

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly usersService: UsersService,
    private readonly paymentSettingsService: PaymentSettingsService,
  ) {}

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.usersService.toPublic(user);
  }

  @Get('stats')
  getStats() {
    return this.adminService.getStats();
  }

  @Get('payment-settings')
  getPaymentSettings() {
    return this.paymentSettingsService.getAdminSettings();
  }

  @Patch('payment-settings')
  updatePaymentSettings(@Body() dto: UpdatePaymentSettingsDto) {
    return this.paymentSettingsService.updateSettings(dto);
  }

  @Get('payments')
  listPayments(@Query('status') status?: string) {
    const parsed =
      status &&
      Object.values(PaymentOrderStatus).includes(status as PaymentOrderStatus)
        ? (status as PaymentOrderStatus)
        : undefined;
    return this.adminService.listPaymentOrders(parsed);
  }

  @Post('payments/:id/confirm')
  async confirmPayment(@Param('id') id: string) {
    const result = await this.adminService.confirmPaymentOrder(id);
    return {
      order: result.order,
      user: this.usersService.toPublic(result.user),
      message: 'Paiement confirmé, abonnement activé.',
    };
  }

  @Post('payments/:id/reject')
  rejectPayment(@Param('id') id: string) {
    return this.adminService.rejectPaymentOrder(id);
  }

  @Get('listings')
  listListings(@Query('status') status?: string) {
    const parsed =
      status && Object.values(ListingStatus).includes(status as ListingStatus)
        ? (status as ListingStatus)
        : undefined;
    return this.adminService.listListings(parsed);
  }

  @Patch('listings/:id/status')
  updateListingStatus(
    @Param('id') id: string,
    @Body() dto: UpdateListingStatusDto,
  ) {
    return this.adminService.updateListingStatus(id, dto.status);
  }

  @Get('users')
  async listUsers() {
    const users = await this.adminService.listUsers();
    return users.map((u) => this.usersService.toPublic(u));
  }

  @Patch('users/:id/role')
  async setRole(@Param('id') id: string, @Body() dto: SetRoleDto) {
    const user = await this.adminService.setUserRole(id, dto.role);
    return this.usersService.toPublic(user);
  }
}
