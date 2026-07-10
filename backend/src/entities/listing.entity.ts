import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Category } from './category.entity';
import { User } from './user.entity';

export enum ListingStatus {
  ACTIVE = 'ACTIVE',
  SOLD = 'SOLD',
  DRAFT = 'DRAFT',
  MODERATED = 'MODERATED',
}

@Entity('listings')
@Index('IDX_listings_status_created', ['status', 'createdAt'])
@Index('IDX_listings_category_status', ['categoryId', 'status'])
@Index('IDX_listings_user_status', ['userId', 'status'])
export class Listing {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price: number;

  @Column({ default: 'XAF' })
  currency: string;

  @Column({ default: 'Ndjamena' })
  city: string;

  @Column({ type: 'jsonb', default: [] })
  images: string[];

  @Column({ type: 'jsonb', default: [] })
  videos: string[];

  @Column({ type: 'enum', enum: ListingStatus, default: ListingStatus.ACTIVE })
  status: ListingStatus;

  @Column({ name: 'category_id' })
  categoryId: string;

  @Column({ name: 'custom_category_name', type: 'varchar', nullable: true })
  customCategoryName: string | null;

  @ManyToOne(() => Category, (category) => category.listings, {
    eager: true,
  })
  @JoinColumn({ name: 'category_id' })
  category: Category;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, (user) => user.listings, { eager: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
