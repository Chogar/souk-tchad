import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import configuration from './config/configuration';
import { Category } from './entities/category.entity';
import { Conversation } from './entities/conversation.entity';
import { DeviceToken } from './entities/device-token.entity';
import { EmailToken } from './entities/email-token.entity';
import { RegistrationOtp } from './entities/registration-otp.entity';
import { Favorite } from './entities/favorite.entity';
import { Listing } from './entities/listing.entity';
import { Message } from './entities/message.entity';
import { PaymentOrder } from './entities/payment-order.entity';
import { PaymentSettings } from './entities/payment-settings.entity';
import { User } from './entities/user.entity';
import { AiModule } from './modules/ai/ai.module';
import { AuthModule } from './modules/auth/auth.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ChatModule } from './modules/chat/chat.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { ListingsModule } from './modules/listings/listings.module';
import { MailModule } from './modules/mail/mail.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { UsersModule } from './modules/users/users.module';
import { AdminModule } from './modules/admin/admin.module';

const entities = [
  User,
  Category,
  Listing,
  Favorite,
  Conversation,
  Message,
  DeviceToken,
  EmailToken,
  RegistrationOtp,
  PaymentOrder,
  PaymentSettings,
];

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60_000,
        limit: 120,
      },
      {
        name: 'auth',
        ttl: 60_000,
        limit: 20,
      },
    ]),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('database.host'),
        port: configService.get<number>('database.port'),
        username: configService.get<string>('database.username'),
        password: configService.get<string>('database.password'),
        database: configService.get<string>('database.name'),
        entities,
        synchronize: configService.get<string>('NODE_ENV') !== 'production',
      }),
    }),
    MailModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ListingsModule,
    FavoritesModule,
    ChatModule,
    NotificationsModule,
    AiModule,
    SubscriptionsModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
