import { IsNotEmpty, IsString } from 'class-validator';

export class ImproveListingDto {
  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  description: string;
}
