import {
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @ValidateIf((o: UpdateProfileDto) => !!o.phone?.trim())
  @Matches(/^\+?[0-9]{8,15}$/, {
    message: 'Numéro invalide (8 à 15 chiffres, ex: +23566000000)',
  })
  phone?: string;
}
