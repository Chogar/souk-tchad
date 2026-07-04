/**
 * Initialise le schéma PostgreSQL en production (à lancer UNE SEULE FOIS).
 * Usage sur le serveur LWS :
 *   cd backend && npm run db:init-prod
 */
import { config } from 'dotenv';
import { DataSource } from 'typeorm';
import { seedCategories } from '../src/database/seeds/categories.seed';
import { Category } from '../src/entities/category.entity';
import { Conversation } from '../src/entities/conversation.entity';
import { DeviceToken } from '../src/entities/device-token.entity';
import { EmailToken } from '../src/entities/email-token.entity';
import { Favorite } from '../src/entities/favorite.entity';
import { Listing } from '../src/entities/listing.entity';
import { Message } from '../src/entities/message.entity';
import { RegistrationOtp } from '../src/entities/registration-otp.entity';
import { User } from '../src/entities/user.entity';

config();

async function main() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DATABASE_HOST ?? 'localhost',
    port: Number(process.env.DATABASE_PORT ?? 5432),
    username: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
    entities: [
      User,
      Category,
      Listing,
      Favorite,
      Conversation,
      Message,
      DeviceToken,
      EmailToken,
      RegistrationOtp,
    ],
    synchronize: true,
  });

  await dataSource.initialize();
  console.log('✅ Tables créées / synchronisées');
  await seedCategories(dataSource);
  console.log('✅ Catégories par défaut insérées');
  await dataSource.destroy();
  console.log('🎉 Base prête pour la production');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
