import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Throttle } from '@nestjs/throttler';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';
import type { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { User } from '../../entities/user.entity';
import { PaymentSettingsService } from '../payment-settings/payment-settings.service';
import { UsersService } from '../users/users.service';
import {
  ConfirmPaymentDto,
  plainToCheckoutDto,
} from './dto/checkout.dto';
import { SubscribeDto } from './dto/subscribe.dto';
import { SubscriptionsService } from './subscriptions.service';

@Controller('subscriptions')
export class SubscriptionsController {
  constructor(
    private readonly subscriptionsService: SubscriptionsService,
    private readonly usersService: UsersService,
    private readonly paymentSettingsService: PaymentSettingsService,
  ) {}

  @Get('plans')
  getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @Get('payment-instructions')
  getPaymentInstructions() {
    return this.subscriptionsService.getPaymentInstructions();
  }

  @Post('subscribe')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  async subscribe(@CurrentUser() user: User, @Body() dto: SubscribeDto) {
    const updated = await this.subscriptionsService.subscribe(
      user.id,
      dto.plan,
    );
    return this.usersService.toPublic(updated);
  }

  /**
   * Demande d’abonnement payant :
   * numéro Airtel/Moov + capture d’écran → ordre PENDING (validation admin).
   */
  @Post('checkout')
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @UseInterceptors(
    FileInterceptor('proof', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'payments'),
        filename: (_req, file, cb) => {
          cb(null, `${uuidv4()}${extname(file.originalname) || '.jpg'}`);
        },
      }),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          cb(new Error('Format image non supporté (jpg, png, webp)'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async checkout(
    @CurrentUser() user: User,
    @Req() req: Request,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException(
        'Ajoutez une capture d’écran du paiement Mobile Money',
      );
    }

    // Lire req.body après multer (évite ValidationPipe sur multipart).
    const dto = plainToCheckoutDto(
      (req.body ?? {}) as Record<string, unknown>,
    );
    const proofImageUrl = `/uploads/payments/${file.filename}`;
    const result = await this.subscriptionsService.checkout(
      user.id,
      dto.plan,
      dto.payerReference,
      dto.provider,
      proofImageUrl,
    );

    // Alerte e-mail admin (non bloquant).
    void this.paymentSettingsService
      .notifyAdminNewPayment(result.order, user)
      .catch(() => {});

    return {
      orderId: result.order.id,
      plan: result.order.plan,
      amount: result.order.amount,
      currency: result.order.currency,
      status: result.order.status,
      provider: result.order.provider,
      payerReference: result.order.payerReference,
      proofImageUrl: result.order.proofImageUrl,
      instructions: result.instructions,
      message:
        'Demande reçue. L’administrateur activera votre abonnement après vérification du paiement.',
    };
  }

  @Get('orders/pending')
  @UseGuards(JwtAuthGuard)
  getPending(@CurrentUser() user: User) {
    return this.subscriptionsService.getMyPendingOrders(user.id);
  }

  /** Confirmation ops / webhook (secret partagé). */
  @Post('confirm-payment')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  async confirmPayment(@Body() dto: ConfirmPaymentDto) {
    const updated = await this.subscriptionsService.confirmPayment(
      dto.orderId,
      dto.secret,
    );
    return this.usersService.toPublic(updated);
  }
}
