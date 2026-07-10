import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserPlan } from './user.entity';

export enum PaymentOrderStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED',
}

@Entity('payment_orders')
@Index('IDX_payment_orders_user_status', ['userId', 'status'])
export class PaymentOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ type: 'enum', enum: UserPlan })
  plan: UserPlan;

  @Column({ type: 'int' })
  amount: number;

  @Column({ default: 'XAF' })
  currency: string;

  @Column({ type: 'enum', enum: PaymentOrderStatus, default: PaymentOrderStatus.PENDING })
  status: PaymentOrderStatus;

  /** Numéro Airtel Money / Moov Money utilisé pour payer. */
  @Column({ name: 'payer_reference', type: 'varchar', nullable: true })
  payerReference: string | null;

  /** Capture d’écran du paiement (preuve pour validation admin). */
  @Column({ name: 'proof_image_url', type: 'varchar', nullable: true })
  proofImageUrl: string | null;

  /** Opérateur : airtel_money | moov_money */
  @Column({ name: 'provider', type: 'varchar', default: 'manual_momo' })
  provider: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
