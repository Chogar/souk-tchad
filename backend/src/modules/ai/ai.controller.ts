import {
  BadRequestException,
  Body,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AiService } from './ai.service';
import { ImproveListingDto } from './dto/improve-listing.dto';
import { TranslateDto } from './dto/translate.dto';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('translate')
  translate(@Body() dto: TranslateDto) {
    return this.aiService.translate(dto.text, dto.targetLang);
  }

  @Post('improve-listing')
  improveListing(@Body() dto: ImproveListingDto) {
    return this.aiService.improveListing(dto.title, dto.description);
  }

  @Post('search-by-image')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp)$/)) {
          cb(new Error('Format image non supporté'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  searchByImage(@UploadedFile() file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Image requise');
    }
    return this.aiService.searchByImage(file.buffer, file.mimetype);
  }
}
