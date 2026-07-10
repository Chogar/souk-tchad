import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentSettings } from '../../entities/payment-settings.entity';
import { MailModule } from '../mail/mail.module';
import { PaymentSettingsService } from './payment-settings.service';

@Module({
  imports: [TypeOrmModule.forFeature([PaymentSettings]), MailModule],
  providers: [PaymentSettingsService],
  exports: [PaymentSettingsService],
})
export class PaymentSettingsModule {}
