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

  await dataSource.initialize();
  await seedDevUser(dataSource);
  await dataSource.destroy();
  console.log('✅ Comptes de test mis à jour');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
