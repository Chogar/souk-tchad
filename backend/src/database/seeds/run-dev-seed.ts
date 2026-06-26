import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import { Category } from '../../entities/category.entity';
import { Conversation } from '../../entities/conversation.entity';
import { DeviceToken } from '../../entities/device-token.entity';
import { EmailToken } from '../../entities/email-token.entity';
import { Favorite } from '../../entities/favorite.entity';
import { Listing } from '../../entities/listing.entity';
import { Message } from '../../entities/message.entity';
import { User } from '../../entities/user.entity';
import { seedCategories } from './categories.seed';
import { clearDevListings, seedDevListings } from './dev-listings.seed';
import { DEMO_PREFIX, DEMO_TARGET_COUNT } from './demo-listings.catalog';
import { seedDevUser } from './dev-user.seed';

config();

async function main() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DATABASE_HOST ?? 'localhost',
    port: Number(process.env.DATABASE_PORT ?? 5432),
    username: process.env.DATABASE_USER ?? 'souk_tchad',
    password: process.env.DATABASE_PASSWORD ?? 'souk_tchad_dev',
    database: process.env.DATABASE_NAME ?? 'souk_tchad',
    entities: [
      User,
      Category,
      Listing,
      Favorite,
      Conversation,
      Message,
      DeviceToken,
      EmailToken,
    ],
    synchronize: false,
  });

  const reset = process.env.RESET_DEMO === '1';

  await dataSource.initialize();
  await seedCategories(dataSource);
  await seedDevUser(dataSource);

  if (reset) {
    const removed = await clearDevListings(dataSource);
    console.log(`🗑️  Annonces « ${DEMO_PREFIX} » supprimées : ${removed}`);
  }

  const created = await seedDevListings(dataSource);
  const total = await dataSource.getRepository(Listing).count();

  await dataSource.destroy();

  console.log(`✅ Comptes de test : OK`);
  console.log(`✅ Annonces démo créées : ${created} nouvelle(s)`);
  console.log(`📦 Total annonces en base : ${total}`);
  console.log(`   (objectif : 100 annonces « [Démo] » — 8 catégories, images picsum)`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
