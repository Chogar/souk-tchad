import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Not, Repository } from 'typeorm';
import { Conversation } from '../../entities/conversation.entity';
import { Listing } from '../../entities/listing.entity';
import { Message } from '../../entities/message.entity';
import { User } from '../../entities/user.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Conversation)
    private readonly conversationsRepository: Repository<Conversation>,
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
    @InjectRepository(Listing)
    private readonly listingsRepository: Repository<Listing>,
  ) {}

  async getOrCreateConversation(
    buyer: User,
    listingId: string,
  ): Promise<Conversation> {
    const listing = await this.listingsRepository.findOne({
      where: { id: listingId },
    });
    if (!listing) {
      throw new NotFoundException('Annonce introuvable');
    }
    if (listing.userId === buyer.id) {
      throw new ForbiddenException('Vous ne pouvez pas vous contacter vous-même');
    }

    let conversation = await this.conversationsRepository.findOne({
      where: { listingId, buyerId: buyer.id },
    });

    if (!conversation) {
      conversation = this.conversationsRepository.create({
        listingId,
        buyerId: buyer.id,
        sellerId: listing.userId,
      });
      conversation = await this.conversationsRepository.save(conversation);
    }

    return this.conversationsRepository.findOneOrFail({
      where: { id: conversation.id },
      relations: { listing: true, buyer: true, seller: true },
    });
  }

  async getConversationById(id: string): Promise<Conversation> {
    const conversation = await this.conversationsRepository.findOne({
      where: { id },
    });
    if (!conversation) {
      throw new NotFoundException('Conversation introuvable');
    }
    return conversation;
  }

  async getUserConversations(userId: string) {
    const conversations = await this.conversationsRepository
      .createQueryBuilder('c')
      .leftJoinAndSelect('c.listing', 'listing')
      .leftJoinAndSelect('listing.category', 'category')
      .leftJoinAndSelect('listing.user', 'listingUser')
      .leftJoinAndSelect('c.buyer', 'buyer')
      .leftJoinAndSelect('c.seller', 'seller')
      .where('c.buyerId = :userId OR c.sellerId = :userId', { userId })
      .orderBy('c.updatedAt', 'DESC')
      .getMany();

    return Promise.all(
      conversations.map(async (conversation) => {
        const lastMessage = await this.messagesRepository.findOne({
          where: { conversationId: conversation.id },
          order: { createdAt: 'DESC' },
          relations: { sender: true },
        });
        const unreadCount = await this.messagesRepository.count({
          where: {
            conversationId: conversation.id,
            read: false,
            senderId: Not(userId),
          },
        });

        return {
          ...conversation,
          lastMessage: lastMessage
            ? {
                content: lastMessage.content,
                createdAt: lastMessage.createdAt,
                senderId: lastMessage.senderId,
              }
            : null,
          unreadCount,
        };
      }),
    );
  }

  async getUnreadTotal(userId: string): Promise<number> {
    return this.messagesRepository
      .createQueryBuilder('m')
      .innerJoin('m.conversation', 'c')
      .where('(c.buyerId = :userId OR c.sellerId = :userId)', { userId })
      .andWhere('m.read = false')
      .andWhere('m.senderId != :userId', { userId })
      .getCount();
  }

  async markConversationAsRead(
    userId: string,
    conversationId: string,
  ): Promise<void> {
    await this.ensureParticipant(userId, conversationId);
    await this.messagesRepository.update(
      {
        conversationId,
        read: false,
        senderId: Not(userId),
      },
      { read: true },
    );
  }

  async getMessages(
    userId: string,
    conversationId: string,
  ): Promise<Message[]> {
    await this.ensureParticipant(userId, conversationId);
    return this.messagesRepository.find({
      where: { conversationId },
      order: { createdAt: 'ASC' },
      relations: { sender: true },
    });
  }

  async sendMessage(
    senderId: string,
    conversationId: string,
    content: string,
  ): Promise<Message> {
    await this.ensureParticipant(senderId, conversationId);

    const message = this.messagesRepository.create({
      conversationId,
      senderId,
      content,
    });
    const saved = await this.messagesRepository.save(message);

    await this.conversationsRepository.update(conversationId, {
      updatedAt: new Date(),
    });

    return this.messagesRepository.findOneOrFail({
      where: { id: saved.id },
      relations: { sender: true },
    });
  }

  private async ensureParticipant(
    userId: string,
    conversationId: string,
  ): Promise<Conversation> {
    const conversation = await this.conversationsRepository.findOne({
      where: { id: conversationId },
    });
    if (!conversation) {
      throw new NotFoundException('Conversation introuvable');
    }
    if (conversation.buyerId !== userId && conversation.sellerId !== userId) {
      throw new ForbiddenException('Accès refusé');
    }
    return conversation;
  }
}
