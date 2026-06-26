import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { DataSource, In, Repository } from 'typeorm';
import { Conversation } from '../../entities/conversation.entity';
import { Favorite } from '../../entities/favorite.entity';
import { Listing } from '../../entities/listing.entity';
import { Message } from '../../entities/message.entity';
import { RegistrationOtp } from '../../entities/registration-otp.entity';
import { User, UserPlan } from '../../entities/user.entity';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email: email.trim().toLowerCase() },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        phone: true,
        googleId: true,
        passwordHash: true,
        plan: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { googleId } });
  }

  async createFromGoogle(data: {
    email: string;
    name: string;
    googleId: string;
    avatarUrl?: string;
  }): Promise<User> {
    const user = this.usersRepository.create({
      email: data.email,
      name: data.name,
      googleId: data.googleId,
      avatarUrl: data.avatarUrl ?? null,
      isEmailVerified: true,
      plan: UserPlan.FREE,
    });
    return this.usersRepository.save(user);
  }

  async createWithPassword(data: {
    email: string;
    name: string;
    passwordHash: string;
    phone?: string;
    isEmailVerified?: boolean;
  }): Promise<User> {
    const user = this.usersRepository.create({
      email: data.email,
      name: data.name,
      passwordHash: data.passwordHash,
      phone: data.phone?.trim() || null,
      isEmailVerified: data.isEmailVerified ?? false,
      plan: UserPlan.FREE,
    });
    return this.usersRepository.save(user);
  }

  async finalizePasswordRegistration(
    userId: string,
    data: { name: string; phone?: string; passwordHash: string },
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) throw new NotFoundException('Utilisateur introuvable');

    user.name = data.name.trim();
    user.phone = data.phone?.trim() || null;
    user.passwordHash = data.passwordHash;
    user.isEmailVerified = true;
    return this.usersRepository.save(user);
  }

  async verifyEmail(userId: string): Promise<void> {
    await this.usersRepository.update(userId, { isEmailVerified: true });
  }

  async linkGoogleAccount(
    user: User,
    data: { googleId: string; avatarUrl?: string },
  ): Promise<User> {
    user.googleId = data.googleId;
    user.isEmailVerified = true;
    if (data.avatarUrl) user.avatarUrl = data.avatarUrl;
    return this.usersRepository.save(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.findById(userId);
    if (!user) throw new NotFoundException('Utilisateur introuvable');

    if (dto.name) user.name = dto.name.trim();
    if (dto.phone !== undefined) {
      user.phone = dto.phone.trim() || null;
    }
    const saved = await this.usersRepository.save(user);
    return this.toPublic(saved);
  }

  async updateAvatar(userId: string, avatarUrl: string) {
    const user = await this.findById(userId);
    if (!user) throw new NotFoundException('Utilisateur introuvable');

    user.avatarUrl = avatarUrl;
    const saved = await this.usersRepository.save(user);
    return this.toPublic(saved);
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.findByEmail(
      (await this.findById(userId))?.email ?? '',
    );
    if (!user?.passwordHash) {
      throw new BadRequestException(
        'Compte Google — mot de passe non modifiable ici',
      );
    }

    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Mot de passe actuel incorrect');
    }

    user.passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await this.usersRepository.save(user);
    return { message: 'Mot de passe mis à jour' };
  }

  async deleteAccount(userId: string): Promise<{ message: string }> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    await this.dataSource.transaction(async (manager) => {
      const listings = await manager.find(Listing, {
        where: { userId },
        select: { id: true },
      });
      const listingIds = listings.map((listing) => listing.id);

      if (listingIds.length > 0) {
        await manager.delete(Favorite, { listingId: In(listingIds) });
      }

      const conversationQuery = manager
        .createQueryBuilder(Conversation, 'conversation')
        .select('conversation.id')
        .where('conversation.buyerId = :userId', { userId })
        .orWhere('conversation.sellerId = :userId', { userId });

      if (listingIds.length > 0) {
        conversationQuery.orWhere('conversation.listingId IN (:...listingIds)', {
          listingIds,
        });
      }

      const conversations = await conversationQuery.getMany();
      const conversationIds = conversations.map((c) => c.id);

      if (conversationIds.length > 0) {
        await manager.delete(Message, { conversationId: In(conversationIds) });
        await manager.delete(Conversation, { id: In(conversationIds) });
      }

      await manager.delete(Listing, { userId });
      await manager.delete(RegistrationOtp, { email: user.email });
      await manager.delete(User, { id: userId });
    });

    return { message: 'Compte supprimé définitivement.' };
  }

  toPublic(user: User) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      phone: user.phone,
      plan: user.plan,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt,
    };
  }
}
