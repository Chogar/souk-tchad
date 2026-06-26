import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import * as admin from 'firebase-admin';
import { Repository } from 'typeorm';
import { DeviceToken } from '../../entities/device-token.entity';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseReady = false;

  constructor(
    @InjectRepository(DeviceToken)
    private readonly tokensRepository: Repository<DeviceToken>,
    private readonly configService: ConfigService,
  ) {
    this.initFirebase();
  }

  private initFirebase() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');
    const privateKey = this.configService.get<string>('firebase.privateKey');

    if (!projectId || !clientEmail || !privateKey) {
      this.logger.warn('Firebase non configuré — notifications push désactivées');
      return;
    }

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
    }
    this.firebaseReady = true;
  }

  async registerToken(
    userId: string,
    token: string,
    platform = 'android',
  ): Promise<DeviceToken> {
    const existing = await this.tokensRepository.findOne({ where: { token } });
    if (existing) {
      existing.userId = userId;
      existing.platform = platform;
      return this.tokensRepository.save(existing);
    }

    const deviceToken = this.tokensRepository.create({
      userId,
      token,
      platform,
    });
    return this.tokensRepository.save(deviceToken);
  }

  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const tokens = await this.tokensRepository.find({ where: { userId } });
    if (!tokens.length) return;

    if (!this.firebaseReady) {
      this.logger.log(`[FCM simulé] → ${userId}: ${title} — ${body}`);
      return;
    }

    const messaging = admin.messaging();
    await messaging.sendEachForMulticast({
      tokens: tokens.map((t) => t.token),
      notification: { title, body },
      data,
    });
  }
}
