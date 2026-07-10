import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PaymentOrder,
  PaymentOrderStatus,
} from '../../entities/payment-order.entity';
import { User, UserPlan } from '../../entities/user.entity';
import { PaymentSettingsService } from '../payment-settings/payment-settings.service';

/** Plans affichés : Gratuit (5), Or (30 / 500 FCFA), Illimité (1000 FCFA). */
export const PLAN_DETAILS = {
  [UserPlan.FREE]: {
    name: 'Gratuit',
    price: 0,
    maxListings: 5,
    featuredPerMonth: 0,
    hasShop: false,
    hasAds: true,
  },
  [UserPlan.SILVER]: {
    name: 'Or',
    price: 500,
    maxListings: 30,
    featuredPerMonth: 5,
    hasShop: false,
    hasAds: false,
  },
  [UserPlan.GOLD]: {
    name: 'Or',
    price: 500,
    maxListings: 30,
    featuredPerMonth: 5,
    hasShop: false,
    hasAds: false,
  },
  [UserPlan.PROFESSIONAL]: {
    name: 'Illimité',
    price: 1000,
    maxListings: -1,
    featuredPerMonth: -1,
    hasShop: true,
    hasAds: false,
  },
};

const PUBLIC_PLANS: UserPlan[] = [
  UserPlan.FREE,
  UserPlan.GOLD,
  UserPlan.PROFESSIONAL,
];

const PAID_PLANS = new Set<UserPlan>([
  UserPlan.SILVER,
  UserPlan.GOLD,
  UserPlan.PROFESSIONAL,
]);

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(PaymentOrder)
    private readonly paymentOrdersRepository: Repository<PaymentOrder>,
    private readonly configService: ConfigService,
    private readonly paymentSettingsService: PaymentSettingsService,
  ) {}

  getPlans() {
    const mode = this.configService.get<string>('payments.mode') ?? 'manual';
    return PUBLIC_PLANS.map((key) => ({
      id: key,
      ...PLAN_DETAILS[key],
      paymentRequired: PAID_PLANS.has(key),
      paymentAvailable: PAID_PLANS.has(key) ? mode !== 'disabled' : true,
    }));
  }

  async getPaymentInstructions() {
    return this.paymentSettingsService.getPublicInstructions();
  }

  async subscribe(userId: string, plan: UserPlan): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    if (plan === UserPlan.FREE) {
      user.plan = UserPlan.FREE;
      return this.usersRepository.save(user);
    }

    if (!PAID_PLANS.has(plan)) {
      throw new ForbiddenException('Plan non autorisé');
    }

    throw new HttpException(
      {
        message:
          'Utilisez /subscriptions/checkout pour démarrer le paiement Mobile Money.',
        code: 'CHECKOUT_REQUIRED',
      },
      HttpStatus.PAYMENT_REQUIRED,
    );
  }

  async checkout(
    userId: string,
    plan: UserPlan,
    payerReference: string | undefined,
    provider: 'airtel_money' | 'moov_money',
    proofImageUrl: string,
  ): Promise<{
    order: PaymentOrder;
    instructions: Awaited<
      ReturnType<SubscriptionsService['getPaymentInstructions']>
    >;
  }> {
    if (!PAID_PLANS.has(plan)) {
      throw new BadRequestException('Ce plan ne nécessite pas de paiement');
    }

    const phoneInput = payerReference?.trim() ?? '';
    if (phoneInput.length > 0 && phoneInput.length < 8) {
      throw new BadRequestException(
        'Indiquez le numéro Airtel Money ou Moov Money utilisé pour payer',
      );
    }
    if (!proofImageUrl?.startsWith('/uploads/payments/')) {
      throw new BadRequestException(
        'Capture d’écran du paiement requise pour validation',
      );
    }

    const mode = this.configService.get<string>('payments.mode') ?? 'manual';
    if (mode === 'disabled') {
      throw new HttpException(
        'Les paiements sont temporairement désactivés.',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }

    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    const instructions = await this.paymentSettingsService.getPublicInstructions();
    let phone = phoneInput;
    if (phone.length < 8) {
      phone = user.phone?.trim() ?? '';
    }
    if (phone.length < 8) {
      phone =
        provider === 'moov_money'
          ? instructions.moovMoneyNumber
          : instructions.airtelMoneyNumber;
    }

    const details = PLAN_DETAILS[plan];
    const order = await this.paymentOrdersRepository.save(
      this.paymentOrdersRepository.create({
        userId,
        plan,
        amount: details.price,
        currency: 'XAF',
        status: PaymentOrderStatus.PENDING,
        payerReference: phone,
        proofImageUrl,
        provider,
      }),
    );

    return {
      order,
      instructions: await this.paymentSettingsService.getPublicInstructions(),
    };
  }

  async confirmPayment(orderId: string, secret: string): Promise<User> {
    const expected =
      this.configService.get<string>('payments.webhookSecret') ?? '';
    if (!expected || secret !== expected) {
      throw new UnauthorizedException('Secret de confirmation invalide');
    }

    const order = await this.paymentOrdersRepository.findOne({
      where: { id: orderId },
    });
    if (!order) {
      throw new NotFoundException('Commande introuvable');
    }
    if (order.status === PaymentOrderStatus.PAID) {
      const user = await this.usersRepository.findOneOrFail({
        where: { id: order.userId },
      });
      return user;
    }
    if (order.status !== PaymentOrderStatus.PENDING) {
      throw new BadRequestException('Commande non payable');
    }

    order.status = PaymentOrderStatus.PAID;
    await this.paymentOrdersRepository.save(order);

    const user = await this.usersRepository.findOne({
      where: { id: order.userId },
    });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }
    user.plan = order.plan === UserPlan.SILVER ? UserPlan.GOLD : order.plan;
    return this.usersRepository.save(user);
  }

  async getMyPendingOrders(userId: string) {
    return this.paymentOrdersRepository.find({
      where: { userId, status: PaymentOrderStatus.PENDING },
      order: { createdAt: 'DESC' },
    });
  }

  getMaxListings(plan: UserPlan): number {
    return (
      PLAN_DETAILS[plan]?.maxListings ?? PLAN_DETAILS[UserPlan.FREE].maxListings
    );
  }
}
