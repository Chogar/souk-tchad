import { IsEnum } from 'class-validator';
import { UserPlan } from '../../../entities/user.entity';

export class SubscribeDto {
  @IsEnum(UserPlan)
  plan: UserPlan;
}
