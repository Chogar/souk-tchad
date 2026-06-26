import { Logger } from '@nestjs/common';
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

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly notificationsService: NotificationsService,
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

      const payload = this.jwtService.verify<{ sub: string }>(token);
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
  handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.join(`conversation:${data.conversationId}`);
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; content: string },
  ) {
    const userId = client.data.userId as string;
    if (!userId) return;

    const message = await this.chatService.sendMessage(
      userId,
      data.conversationId,
      data.content,
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
