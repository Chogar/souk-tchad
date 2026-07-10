import { Logger, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DataSource } from 'typeorm';
import { mkdirSync } from 'fs';
import { join } from 'path';
import express, { NextFunction, Request, Response } from 'express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { seedCategories } from './database/seeds/categories.seed';
import { seedDevListings } from './database/seeds/dev-listings.seed';
import { seedDevUser } from './database/seeds/dev-user.seed';

const DEV_JWT_SECRETS = new Set([
  'dev-secret-change-me',
  'dev-secret',
  'change-me-in-production-use-long-random-string',
]);

function assertProductionSecrets(config: ConfigService) {
  if (process.env.NODE_ENV !== 'production') return;

  const jwtSecret = config.get<string>('jwt.secret') ?? '';
  if (!jwtSecret || DEV_JWT_SECRETS.has(jwtSecret) || jwtSecret.length < 32) {
    throw new Error(
      'JWT_SECRET manquant ou trop faible pour la production (min. 32 caractères, pas de valeur par défaut).',
    );
  }

  const dbPassword = config.get<string>('database.password') ?? '';
  if (!dbPassword || dbPassword === 'souk_tchad_dev') {
    throw new Error(
      'DATABASE_PASSWORD invalide pour la production (valeur de développement interdite).',
    );
  }
}

function parseCorsOrigins(raw?: string): boolean | string[] {
  if (!raw || raw.trim() === '' || raw.trim() === '*') {
    // Dev : refléter l'origine. Prod : liste obligatoire via CORS_ORIGINS.
    return process.env.NODE_ENV === 'production' ? [] : true;
  }
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

function mountUploads(app: NestExpressApplication, jwtService: JwtService) {
  const uploadsRoot = join(process.cwd(), 'uploads');

  const requireJwt: express.RequestHandler = (
    req: Request,
    res: Response,
    next: NextFunction,
  ) => {
    const header = req.headers.authorization;
    const bearer =
      typeof header === 'string' && header.startsWith('Bearer ')
        ? header.slice(7)
        : undefined;
    const token =
      (typeof req.query.token === 'string' ? req.query.token : undefined) ??
      bearer;

    if (!token) {
      res.status(401).json({ message: 'Authentification requise' });
      return;
    }
    try {
      jwtService.verify(token);
      next();
    } catch {
      res.status(401).json({ message: 'Jeton invalide' });
    }
  };

  // Public : photos d'annonces + avatars
  app.use('/uploads/listings', express.static(join(uploadsRoot, 'listings')));
  app.use('/uploads/avatars', express.static(join(uploadsRoot, 'avatars')));

  // Privé : chat / voix (JWT header ou ?token= pour Image.network)
  app.use(
    '/uploads/chat',
    requireJwt,
    express.static(join(uploadsRoot, 'chat')),
  );
  app.use(
    '/uploads/voice',
    requireJwt,
    express.static(join(uploadsRoot, 'voice')),
  );
  app.use(
    '/uploads/payments',
    requireJwt,
    express.static(join(uploadsRoot, 'payments')),
  );
}

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
  mkdirSync(join(process.cwd(), 'uploads', 'payments'), { recursive: true });

  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);
  const jwtService = app.get(JwtService);
  const logger = new Logger('Bootstrap');

  assertProductionSecrets(config);

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      contentSecurityPolicy: false,
    }),
  );

  const corsOrigins = parseCorsOrigins(process.env.CORS_ORIGINS);
  if (process.env.NODE_ENV === 'production' && corsOrigins === true) {
    throw new Error(
      'CORS_ORIGINS doit être défini en production (liste d’origines séparées par des virgules).',
    );
  }
  if (Array.isArray(corsOrigins) && corsOrigins.length === 0) {
    throw new Error('CORS_ORIGINS est vide — aucune origine autorisée.');
  }

  app.setGlobalPrefix('api');
  app.enableCors({
    origin: corsOrigins,
    credentials: true,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  mountUploads(app, jwtService);

  // Pages légales publiques (stores / web)
  app.useStaticAssets(join(process.cwd(), 'public'), {
    prefix: '/',
    index: false,
  });

  const dataSource = app.get(DataSource);
  await seedCategories(dataSource);
  if (process.env.NODE_ENV !== 'production') {
    await seedDevUser(dataSource);
    const created = await seedDevListings(dataSource);
    if (created > 0) {
      logger.log(`${created} annonce(s) démo ajoutée(s)`);
    }
  }

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  logger.log(`Souk Tchad API : http://localhost:${port}/api`);
}

bootstrap();
