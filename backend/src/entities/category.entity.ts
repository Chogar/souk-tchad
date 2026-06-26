import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { Listing } from './listing.entity';

@Entity('categories')
export class Category {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  slug: string;

  @Column()
  icon: string;

  @Column({ type: 'int', default: 0 })
  order: number;

  @OneToMany(() => Listing, (listing) => listing.category)
  listings: Listing[];
}
