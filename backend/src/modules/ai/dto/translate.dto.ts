import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class TranslateDto {
  @IsString()
  @IsNotEmpty()
  text: string;

  @IsString()
  @IsOptional()
  targetLang?: string;
}
