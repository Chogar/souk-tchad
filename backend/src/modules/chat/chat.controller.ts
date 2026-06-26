import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { User } from '../../entities/user.entity';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { SendMessageDto } from './dto/send-message.dto';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Get('unread-count')
  getUnreadCount(@CurrentUser() user: User) {
    return this.chatService.getUnreadTotal(user.id);
  }

  @Get('conversations')
  getConversations(@CurrentUser() user: User) {
    return this.chatService.getUserConversations(user.id);
  }

  @Post('conversations/:id/read')
  markAsRead(@CurrentUser() user: User, @Param('id') id: string) {
    return this.chatService.markConversationAsRead(user.id, id);
  }

  @Post('conversations')
  createConversation(
    @CurrentUser() user: User,
    @Body() dto: CreateConversationDto,
  ) {
    return this.chatService.getOrCreateConversation(user, dto.listingId);
  }

  @Get('conversations/:id/messages')
  getMessages(@CurrentUser() user: User, @Param('id') id: string) {
    return this.chatService.getMessages(user.id, id);
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    const message = await this.chatService.sendMessage(
      user.id,
      id,
      dto.content,
    );
    await this.chatGateway.broadcastMessage(id, message);
    return message;
  }

  @Post('conversations/:id/voice')
  @UseInterceptors(
    FileInterceptor('audio', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'voice'),
        filename: (_req, file, cb) => {
          const uniqueName = `${uuidv4()}${extname(file.originalname) || '.m4a'}`;
          cb(null, uniqueName);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async sendVoiceMessage(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const path = `/uploads/voice/${file.filename}`;
    const message = await this.chatService.sendMessage(
      user.id,
      id,
      `voice:${path}`,
    );
    await this.chatGateway.broadcastMessage(id, message);
    return message;
  }

  @Post('conversations/:id/image')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'chat', 'images'),
        filename: (_req, file, cb) => {
          const uniqueName = `${uuidv4()}${extname(file.originalname) || '.jpg'}`;
          cb(null, uniqueName);
        },
      }),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/\/(jpg|jpeg|png|webp|gif)$/)) {
          cb(new Error('Format image non supporté'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async sendImageMessage(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const path = `/uploads/chat/images/${file.filename}`;
    const message = await this.chatService.sendMessage(
      user.id,
      id,
      `image:${path}`,
    );
    await this.chatGateway.broadcastMessage(id, message);
    return message;
  }

  @Post('conversations/:id/document')
  @UseInterceptors(
    FileInterceptor('document', {
      storage: diskStorage({
        destination: join(process.cwd(), 'uploads', 'chat', 'documents'),
        filename: (_req, file, cb) => {
          const uniqueName = `${uuidv4()}${extname(file.originalname)}`;
          cb(null, uniqueName);
        },
      }),
      fileFilter: (_req, file, cb) => {
        const allowed =
          /\/(pdf|msword|vnd\.openxmlformats-officedocument\.wordprocessingml\.document|vnd\.ms-excel|vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet|plain|octet-stream)$/;
        if (!file.mimetype.match(allowed)) {
          cb(new Error('Format document non supporté'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 15 * 1024 * 1024 },
    }),
  )
  async sendDocumentMessage(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const path = `/uploads/chat/documents/${file.filename}`;
    const safeName = file.originalname.replace(/\|/g, '_');
    const message = await this.chatService.sendMessage(
      user.id,
      id,
      `doc:${safeName}|${path}`,
    );
    await this.chatGateway.broadcastMessage(id, message);
    return message;
  }
}
