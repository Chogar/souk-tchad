/**
 * Initialise le schéma PostgreSQL en production (à lancer UNE SEULE FOIS).
 *
 * Local :
 *   npm run build && npm run db:init-prod
 *
 * Terminal cPanel LWS (npm hors PATH) :
 *   bash scripts/cpanel-db-init.sh
 */
import { existsSync, readFileSync } from 'fs';
import { resolve } from 'path';
import { DataSource } from 'typeorm';
import { Category } from '../../entities/category.entity';
import { Conversation } from '../../entities/conversation.entity';
import { DeviceToken } from '../../entities/device-token.entity';
import { EmailToken } from '../../entities/email-token.entity';
import { Favorite } from '../../entities/favorite.entity';
import { Listing } from '../../entities/listing.entity';
import { Message } from '../../entities/message.entity';
import { RegistrationOtp } from '../../entities/registration-otp.entity';
import { User } from '../../entities/user.entity';
import { seedCategories } from './categories.seed';

/** Charge le fichier .env sans dépendre de la commande npm/dotenv CLI. */
function loadEnvFile(): void {
  const envPath = resolve(process.cwd(), '.env');
  if (!existsSync(envPath)) {
    return;
  }

  for (const line of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }
    const eq = trimmed.indexOf('=');
    if (eq === -1) {
      continue;
    }
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

async function main() {
  loadEnvFile();

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
