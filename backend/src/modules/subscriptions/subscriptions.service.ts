import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserPlan } from '../../entities/user.entity';

export const PLAN_DETAILS = {
  [UserPlan.FREE]: {
    name: 'Gratuit',
    price: 0,
    maxListings: 3,
    featuredPerMonth: 0,
    hasShop: false,
    hasAds: true,
  },
  [UserPlan.SILVER]: {
    name: 'Argent',
    price: 5,
    maxListings: 10,
    featuredPerMonth: 2,
    hasShop: false,
    hasAds: false,
  },
  [UserPlan.GOLD]: {
    name: 'Or',
    price: 10,
    maxListings: 30,
    featuredPerMonth: 5,
    hasShop: false,
    hasAds: false,
  },
  [UserPlan.PROFESSIONAL]: {
    name: 'Professionnel',
    price: 20,
    maxListings: -1,
    featuredPerMonth: -1,
    hasShop: true,
    hasAds: false,
  },
};

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  getPlans() {
    return Object.entries(PLAN_DETAILS).map(([key, plan]) => ({
      id: key,
      ...plan,
    }));
  }

  async subscribe(userId: string, plan: UserPlan): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    user.plan = plan;
    return this.usersRepository.save(user);
  }

  getMaxListings(plan: UserPlan): number {
    return PLAN_DETAILS[plan].maxListings;
  }
}
