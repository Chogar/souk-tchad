import { BadRequestException } from '@nestjs/common';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { UserPlan } from '../../../entities/user.entity';

export const PAYMENT_PROVIDERS = ['airtel_money', 'moov_money'] as const;
export type PaymentProvider = (typeof PAYMENT_PROVIDERS)[number];

/** Multer / Dio multipart : valeur parfois tableau ou non-string. */
function toSingleString(value: unknown): string {
  if (value == null) return '';
  if (Array.isArray(value)) {
    return toSingleString(value[0]);
  }
  return String(value).trim();
}

export class CheckoutDto {
  @Transform(({ value }) => toSingleString(value))
  @IsEnum(UserPlan)
  plan: UserPlan;

  /** Numéro du payeur (optionnel — complété côté serveur si absent). */
  @Transform(({ value }) => toSingleString(value).replace(/\s+/g, ''))
  @IsOptional()
  @IsString()
  @MaxLength(30)
  payerReference?: string;

  @Transform(({ value }) => toSingleString(value))
  @IsIn(PAYMENT_PROVIDERS)
  provider: PaymentProvider;

  @IsOptional()
  @Transform(({ value }) => {
    const s = toSingleString(value);
    return s.length === 0 ? undefined : s;
  })
  @IsString()
  @MaxLength(80)
  note?: string;
}

/** Parse manuel du body multipart (évite les faux négatifs ValidationPipe). */
export function plainToCheckoutDto(body: Record<string, unknown>): {
  plan: UserPlan;
  payerReference?: string;
  provider: PaymentProvider;
} {
  const plan = toSingleString(body.plan) as UserPlan;
  const payerReference = toSingleString(body.payerReference).replace(/\s+/g, '');
  const provider = toSingleString(body.provider) as PaymentProvider;

  if (!Object.values(UserPlan).includes(plan)) {
    throw new BadRequestException('Plan invalide');
  }
  if (
    payerReference.length > 0 &&
    (payerReference.length < 8 || payerReference.length > 30)
  ) {
    throw new BadRequestException(
      'Indiquez un numéro Airtel Money ou Moov Money valide',
    );
  }
  if (!PAYMENT_PROVIDERS.includes(provider)) {
    throw new BadRequestException(
      'Choisissez Airtel Money ou Moov Money',
    );
  }

  return {
    plan,
    payerReference: payerReference.length > 0 ? payerReference : undefined,
    provider,
  };
}

export class ConfirmPaymentDto {
  @IsString()
  @MinLength(8)
  orderId: string;

  @IsString()
  @MinLength(8)
  secret: string;
}
