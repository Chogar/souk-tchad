import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { mkdirSync } from 'fs';
import { join } from 'path';
import { AppModule } from './app.module';
import { seedCategories } from './database/seeds/categories.seed';
import { seedDevListings } from './database/seeds/dev-listings.seed';
import { seedDevUser } from './database/seeds/dev-user.seed';

async function bootstrap() {
  mkdirSync(join(process.cwd(), 'uploads', 'listings'), { recursive: true });
  mkdirSync(join(process.cwd(), 'uploads', 'listings', 'videos'), {
    recursive: true,
  });
  mkdirSync(join(process.cwd(), 'uploads', 'avatars'), { recursive: true });
  mkdirSync(join(process.cwd(), 'uploads', 'voice'), { recursive: true });
  mkdirSync(join(process.cwd(), 'uploads', 'chat', 'images'), {
    recursive: true,
  });
  mkdirSync(join(process.cwd(), 'uploads', 'chat', 'documents'), {
    recursive: true,
  });

  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');
  app.enableCors({ origin: true, credentials: true });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const dataSource = app.get(DataSource);
  await seedCategories(dataSource);
  if (process.env.NODE_ENV !== 'production') {
    await seedDevUser(dataSource);
    const created = await seedDevListings(dataSource);
    if (created > 0) {
      console.log(`📦 ${created} annonce(s) démo ajoutée(s)`);
    }
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 Souk Tchad API : http://localhost:${port}/api`);
  console.log(`   Réseau local (iPhone) : http://<IP-du-Mac>:${port}/api`);
}

bootstrap();
