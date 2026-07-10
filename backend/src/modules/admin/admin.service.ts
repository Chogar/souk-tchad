import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Listing, ListingStatus } from '../../entities/listing.entity';
import {
  PaymentOrder,
  PaymentOrderStatus,
} from '../../entities/payment-order.entity';
import { User, UserPlan, UserRole } from '../../entities/user.entity';
import { Conversation } from '../../entities/conversation.entity';
import { Message } from '../../entities/message.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(Listing)
    private readonly listingsRepository: Repository<Listing>,
    @InjectRepository(PaymentOrder)
    private readonly paymentOrdersRepository: Repository<PaymentOrder>,
    @InjectRepository(Conversation)
    private readonly conversationsRepository: Repository<Conversation>,
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
  ) {}

  async getStats() {
    const [
      usersTotal,
      usersVerified,
      listingsActive,
      listingsModerated,
      listingsSold,
      listingsDraft,
      paymentsPending,
      paymentsPaid,
      conversationsTotal,
      messagesTotal,
    ] = await Promise.all([
      this.usersRepository.count(),
      this.usersRepository.count({ where: { isEmailVerified: true } }),
      this.listingsRepository.count({ where: { status: ListingStatus.ACTIVE } }),
      this.listingsRepository.count({
        where: { status: ListingStatus.MODERATED },
      }),
      this.listingsRepository.count({ where: { status: ListingStatus.SOLD } }),
      this.listingsRepository.count({ where: { status: ListingStatus.DRAFT } }),
      this.paymentOrdersRepository.count({
        where: { status: PaymentOrderStatus.PENDING },
      }),
      this.paymentOrdersRepository.count({
        where: { status: PaymentOrderStatus.PAID },
      }),
      this.conversationsRepository.count(),
      this.messagesRepository.count(),
    ]);

    const revenuePaid = await this.paymentOrdersRepository
      .createQueryBuilder('o')
      .select('COALESCE(SUM(o.amount), 0)', 'total')
      .where('o.status = :status', { status: PaymentOrderStatus.PAID })
      .getRawOne<{ total: string }>();

    const planBreakdown = await this.usersRepository
      .createQueryBuilder('u')
      .select('u.plan', 'plan')
      .addSelect('COUNT(*)', 'count')
      .groupBy('u.plan')
      .getRawMany<{ plan: string; count: string }>();

    return {
      users: {
        total: usersTotal,
        verified: usersVerified,
        byPlan: Object.fromEntries(
          planBreakdown.map((row) => [row.plan, Number(row.count)]),
        ),
      },
      listings: {
        active: listingsActive,
        moderated: listingsModerated,
        sold: listingsSold,
        draft: listingsDraft,
        total:
          listingsActive + listingsModerated + listingsSold + listingsDraft,
      },
      payments: {
        pending: paymentsPending,
        paid: paymentsPaid,
        revenueXaf: Number(revenuePaid?.total ?? 0),
      },
      chat: {
        conversations: conversationsTotal,
        messages: messagesTotal,
      },
    };
  }

  async listPaymentOrders(status?: PaymentOrderStatus) {
    const where = status ? { status } : {};
    const orders = await this.paymentOrdersRepository.find({
      where,
      order: { createdAt: 'DESC' },
      take: 100,
    });

    const userIds = [...new Set(orders.map((o) => o.userId))];
    const users =
      userIds.length === 0
        ? []
        : await this.usersRepository
            .createQueryBuilder('u')
            .where('u.id IN (:...userIds)', { userIds })
            .getMany();
    const byId = new Map(users.map((u) => [u.id, u]));

    return orders.map((order) => {
      const user = byId.get(order.userId);
      return {
        ...order,
        user: user
          ? {
              id: user.id,
              email: user.email,
              name: user.name,
              phone: user.phone,
              plan: user.plan,
            }
          : null,
      };
    });
  }

  async confirmPaymentOrder(orderId: string) {
    const order = await this.paymentOrdersRepository.findOne({
      where: { id: orderId },
    });
    if (!order) {
      throw new NotFoundException('Commande introuvable');
    }
    if (order.status === PaymentOrderStatus.PAID) {
      const user = await this.usersRepository.findOneOrFail({
        where: { id: order.userId },
      });
      return { order, user };
    }
    if (order.status !== PaymentOrderStatus.PENDING) {
      throw new BadRequestException('Cette commande ne peut pas être confirmée');
    }

    order.status = PaymentOrderStatus.PAID;
    await this.paymentOrdersRepository.save(order);

    const user = await this.usersRepository.findOne({
      where: { id: order.userId },
    });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }
    user.plan = order.plan === UserPlan.SILVER ? UserPlan.GOLD : order.plan;
    await this.usersRepository.save(user);

    return { order, user };
  }

  async rejectPaymentOrder(orderId: string) {
    const order = await this.paymentOrdersRepository.findOne({
      where: { id: orderId },
    });
    if (!order) {
      throw new NotFoundException('Commande introuvable');
    }
    if (order.status !== PaymentOrderStatus.PENDING) {
      throw new BadRequestException('Seules les commandes en attente peuvent être annulées');
    }
    order.status = PaymentOrderStatus.CANCELLED;
    return this.paymentOrdersRepository.save(order);
  }

  async listListings(status?: ListingStatus) {
    const qb = this.listingsRepository
      .createQueryBuilder('listing')
      .leftJoinAndSelect('listing.category', 'category')
      .leftJoinAndSelect('listing.user', 'user')
      .orderBy('listing.createdAt', 'DESC')
      .take(100);

    if (status) {
      qb.where('listing.status = :status', { status });
    }

    return qb.getMany();
  }

  async updateListingStatus(id: string, status: ListingStatus) {
    const listing = await this.listingsRepository.findOne({
      where: { id },
      relations: { category: true, user: true },
    });
    if (!listing) {
      throw new NotFoundException('Annonce introuvable');
    }
    listing.status = status;
    return this.listingsRepository.save(listing);
  }

  async listUsers() {
    return this.usersRepository.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
  }

  async setUserRole(userId: string, role: UserRole) {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }
    user.role = role;
    return this.usersRepository.save(user);
  }
}
