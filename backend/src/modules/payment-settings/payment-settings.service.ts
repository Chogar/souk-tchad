import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentOrder } from '../../entities/payment-order.entity';
import { PaymentSettings } from '../../entities/payment-settings.entity';
import { User } from '../../entities/user.entity';
import { MailService } from '../mail/mail.service';
import { UpdatePaymentSettingsDto } from './dto/update-payment-settings.dto';

const SETTINGS_ID = 'default';

export type PublicPaymentInstructions = {
  mode: string;
  airtelMoneyNumber: string;
  moovMoneyNumber: string;
  momoNumber: string;
  momoLabel: string;
  currency: string;
};

@Injectable()
export class PaymentSettingsService {
  private readonly logger = new Logger(PaymentSettingsService.name);

  constructor(
    @InjectRepository(PaymentSettings)
    private readonly settingsRepository: Repository<PaymentSettings>,
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
  ) {}

  private defaultMomoNumber(): string {
    return (
      this.configService.get<string>('payments.momoNumber') ?? '+23566000000'
    );
  }

  private defaultMomoLabel(): string {
    return (
      this.configService.get<string>('payments.momoLabel') ?? 'Souk Tchad'
    );
  }

  private defaultNotificationEmail(): string | null {
    const fromEnv =
      this.configService.get<string>('payments.adminEmail') ?? '';
    return fromEnv.trim() || null;
  }

  private async getOrCreateRow(): Promise<PaymentSettings> {
    let row = await this.settingsRepository.findOne({
      where: { id: SETTINGS_ID },
    });
    if (!row) {
      const fallback = this.defaultMomoNumber();
      row = await this.settingsRepository.save(
        this.settingsRepository.create({
          id: SETTINGS_ID,
          airtelMoneyNumber: fallback,
          moovMoneyNumber: fallback,
          notificationEmail: this.defaultNotificationEmail(),
          notifyOnPayment: true,
          momoLabel: this.defaultMomoLabel(),
        }),
      );
    }
    return row;
  }

  async getAdminSettings() {
    const row = await this.getOrCreateRow();
    return {
      airtelMoneyNumber: row.airtelMoneyNumber ?? this.defaultMomoNumber(),
      moovMoneyNumber: row.moovMoneyNumber ?? this.defaultMomoNumber(),
      notificationEmail:
        row.notificationEmail ?? this.defaultNotificationEmail(),
      notifyOnPayment: row.notifyOnPayment,
      momoLabel: row.momoLabel ?? this.defaultMomoLabel(),
      updatedAt: row.updatedAt,
    };
  }

  async updateSettings(dto: UpdatePaymentSettingsDto) {
    const row = await this.getOrCreateRow();
    if (dto.airtelMoneyNumber !== undefined) {
      row.airtelMoneyNumber = dto.airtelMoneyNumber.trim();
    }
    if (dto.moovMoneyNumber !== undefined) {
      row.moovMoneyNumber = dto.moovMoneyNumber.trim();
    }
    if (dto.notificationEmail !== undefined) {
      row.notificationEmail = dto.notificationEmail.trim().toLowerCase();
    }
    if (dto.notifyOnPayment !== undefined) {
      row.notifyOnPayment = dto.notifyOnPayment;
    }
    if (dto.momoLabel !== undefined) {
      row.momoLabel = dto.momoLabel.trim();
    }
    await this.settingsRepository.save(row);
    return this.getAdminSettings();
  }

  async getPublicInstructions(): Promise<PublicPaymentInstructions> {
    const row = await this.getOrCreateRow();
    const fallback = this.defaultMomoNumber();
    const airtel = (row.airtelMoneyNumber ?? fallback).trim();
    const moov = (row.moovMoneyNumber ?? fallback).trim();
    return {
      mode: this.configService.get<string>('payments.mode') ?? 'manual',
      airtelMoneyNumber: airtel,
      moovMoneyNumber: moov,
      momoNumber: airtel,
      momoLabel: row.momoLabel ?? this.defaultMomoLabel(),
      currency: 'XAF',
    };
  }

  async notifyAdminNewPayment(order: PaymentOrder, user: User): Promise<void> {
    const row = await this.getOrCreateRow();
    if (!row.notifyOnPayment) return;

    const to =
      row.notificationEmail?.trim() ||
      this.defaultNotificationEmail() ||
      '';
    if (!to) {
      this.logger.warn(
        'Notification paiement ignorée : aucun e-mail admin configuré',
      );
      return;
    }

    const providerLabel =
      order.provider === 'moov_money'
        ? 'Moov Money'
        : order.provider === 'airtel_money'
          ? 'Airtel Money'
          : order.provider;

    await this.mailService.sendPaymentRequestNotification({
      to,
      orderId: order.id,
      plan: order.plan,
      amount: order.amount,
      currency: order.currency,
      providerLabel,
      payerPhone: order.payerReference ?? '—',
      userName: user.name,
      userEmail: user.email,
      proofImageUrl: order.proofImageUrl,
      appUrl: this.configService.get<string>('app.url') ?? '',
    });
  }
}
