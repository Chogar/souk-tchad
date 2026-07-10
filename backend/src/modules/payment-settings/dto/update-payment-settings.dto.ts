import {
  IsBoolean,
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class UpdatePaymentSettingsDto {
  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(20)
  airtelMoneyNumber?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(20)
  moovMoneyNumber?: string;

  @IsOptional()
  @IsEmail()
  @MaxLength(120)
  notificationEmail?: string;

  @IsOptional()
  @IsBoolean()
  notifyOnPayment?: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  momoLabel?: string;
}
