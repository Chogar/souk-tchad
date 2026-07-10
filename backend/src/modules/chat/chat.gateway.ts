import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatService } from './chat.service';

function wsCorsOrigin(): boolean | string[] {
  const raw = process.env.CORS_ORIGINS;
  if (!raw || raw.trim() === '' || raw.trim() === '*') {
    return process.env.NODE_ENV === 'production' ? [] : true;
  }
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

@WebSocketGateway({
  cors: { origin: wsCorsOrigin(), credentials: true },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly notificationsService: NotificationsService,
    private readonly configService: ConfigService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token =
        (client.handshake.auth?.token as string) ??
        (client.handshake.headers.authorization as string)?.replace(
          'Bearer ',
          '',
        );

      if (!token) {
        client.disconnect();
        return;
      }

      const secret =
        this.configService.get<string>('jwt.secret') ?? 'dev-secret-change-me';
      const payload = this.jwtService.verify<{ sub: string }>(token, {
        secret,
      });
      client.data.userId = payload.sub;
      client.join(`user:${payload.sub}`);
    } catch {
      client.disconnect();
    }
  }

  async broadcastMessage(conversationId: string, message: unknown) {
    this.server
      .to(`conversation:${conversationId}`)
      .emit('new_message', message);
  }

  @SubscribeMessage('join_conversation')
  async handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId || !data?.conversationId) {
      return { error: 'Non autorisé' };
    }

    try {
      await this.chatService.ensureParticipant(userId, data.conversationId);
      client.join(`conversation:${data.conversationId}`);
      return { ok: true };
    } catch (error) {
      this.logger.warn(
        `join_conversation refusé user=${userId} conv=${data.conversationId}`,
      );
      return { error: 'Accès refusé' };
    }
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; content: string },
  ) {
    const userId = client.data.userId as string;
    if (!userId) return;

    const content = (data?.content ?? '').trim();
    if (!data?.conversationId || content.length === 0) {
      return { error: 'Message invalide' };
    }
    if (content.length > 2000) {
      return { error: 'Message trop long (max 2000)' };
    }

    const message = await this.chatService.sendMessage(
      userId,
      data.conversationId,
      content,
    );

    await this.broadcastMessage(data.conversationId, message);

    const conversation = await this.chatService.getConversationById(
      data.conversationId,
    );
    const recipientId =
      conversation.buyerId === userId
        ? conversation.sellerId
        : conversation.buyerId;

    await this.notificationsService.sendToUser(
      recipientId,
      'Nouveau message',
      message.content.slice(0, 100),
      { conversationId: data.conversationId },
    );

    return message;
  }
}
