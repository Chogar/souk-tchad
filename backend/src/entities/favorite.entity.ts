import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Listing } from './listing.entity';
import { User } from './user.entity';

@Entity('favorites')
@Unique(['userId', 'listingId'])
export class Favorite {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => Listing, { onDelete: 'CASCADE', eager: true })
  @JoinColumn({ name: 'listing_id' })
  listing: Listing;

  @Column({ name: 'listing_id' })
  listingId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
