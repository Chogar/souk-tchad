import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private readonly configService: ConfigService) {
    const user = this.configService.get<string>('smtp.user');
    const pass = this.configService.get<string>('smtp.pass');

    if (user && pass) {
      const port = this.configService.get<number>('smtp.port') ?? 587;
      const host = this.configService.get<string>('smtp.host') ?? 'smtp.gmail.com';
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
        ...(port === 587 ? { requireTLS: true } : {}),
      });
      this.logger.log(`SMTP actif (${host}:${port})`);
    }
  }

  async sendVerificationEmail(email: string, token: string): Promise<void> {
    const appUrl = this.configService.get<string>('app.url');
    const verifyUrl = `${appUrl}/api/auth/verify-email?token=${token}`;

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:24px">
        <h2 style="color:#003080">Souk Tchad</h2>
        <p>Bonjour,</p>
        <p>Confirmez votre adresse Gmail pour activer votre compte :</p>
        <p style="margin:28px 0">
          <a href="${verifyUrl}"
             style="background:#003080;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;display:inline-block">
            Valider mon compte
          </a>
        </p>
        <p style="color:#666;font-size:13px">Ce lien expire dans 24 heures.</p>
        <p style="color:#999;font-size:12px">Si vous n'avez pas créé de compte, ignorez ce message.</p>
      </div>
    `;

    await this.send(email, 'Souk Tchad — Validez votre compte', html);
  }

  async sendRegistrationOtpEmail(email: string, code: string): Promise<void> {
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:24px">
        <h2 style="color:#003080">Souk Tchad</h2>
        <p>Bonjour,</p>
        <p>Voici votre code de validation pour créer votre compte :</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px;color:#003080;margin:24px 0">${code}</p>
        <p style="color:#666;font-size:13px">Ce code expire dans 10 minutes.</p>
        <p style="color:#999;font-size:12px">Si vous n'avez pas demandé ce code, ignorez ce message.</p>
      </div>
    `;

    await this.send(email, 'Souk Tchad — Code de validation', html);
  }

  private async send(to: string, subject: string, html: string): Promise<void> {
    if (!this.transporter) {
      this.logger.warn(
        `SMTP non configuré — e-mail simulé pour ${to}: ${subject}`,
      );
      return;
    }

    await this.transporter.sendMail({
      from: this.configService.get<string>('smtp.from'),
      to,
      subject,
      html,
    });
  }
}
