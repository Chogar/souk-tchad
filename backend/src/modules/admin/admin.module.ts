import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Conversation } from '../../entities/conversation.entity';
import { Listing } from '../../entities/listing.entity';
import { Message } from '../../entities/message.entity';
import { PaymentOrder } from '../../entities/payment-order.entity';
import { User } from '../../entities/user.entity';
import { PaymentSettingsModule } from '../payment-settings/payment-settings.module';
import { UsersModule } from '../users/users.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Listing,
      PaymentOrder,
      Conversation,
      Message,
    ]),
    UsersModule,
    PaymentSettingsModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
