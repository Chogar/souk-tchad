import {
  Column,
  Entity,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

/** Paramètres globaux de paiement (une seule ligne : id = default). */
@Entity('payment_settings')
export class PaymentSettings {
  @PrimaryColumn({ default: 'default' })
  id: string;

  @Column({ name: 'airtel_money_number', type: 'varchar', nullable: true })
  airtelMoneyNumber: string | null;

  @Column({ name: 'moov_money_number', type: 'varchar', nullable: true })
  moovMoneyNumber: string | null;

  /** E-mail admin pour recevoir les alertes de nouveaux paiements. */
  @Column({ name: 'notification_email', type: 'varchar', nullable: true })
  notificationEmail: string | null;

  @Column({ name: 'notify_on_payment', default: true })
  notifyOnPayment: boolean;

  @Column({ name: 'momo_label', type: 'varchar', default: 'Souk Tchad' })
  momoLabel: string;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
