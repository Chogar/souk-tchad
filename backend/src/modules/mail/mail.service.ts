import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private readonly configService: ConfigService) {
    const user = this.configService.get<string>('smtp.user')?.trim();
    const pass = this.configService.get<string>('smtp.pass')?.trim();

    if (user && pass) {
      const port = this.configService.get<number>('smtp.port') ?? 587;
      const host =
        this.configService.get<string>('smtp.host') ?? 'smtp.gmail.com';
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
        ...(port === 587 ? { requireTLS: true } : {}),
      });
      this.logger.log(`SMTP actif (${host}:${port} → ${user})`);
    } else {
      this.logger.warn(
        'SMTP non configuré — les e-mails OTP ne seront pas envoyés. Renseignez SMTP_USER + SMTP_PASS dans backend/.env',
      );
    }
  }

  isConfigured(): boolean {
    return this.transporter != null;
  }

  async verifyConnection(): Promise<void> {
    if (!this.transporter) {
      throw new ServiceUnavailableException(
        'SMTP non configuré. Ajoutez SMTP_USER et SMTP_PASS (mot de passe d\'application Gmail).',
      );
    }
    await this.transporter.verify();
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
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:24px;background:#f5f7fb">
        <div style="background:#fff;border-radius:12px;padding:28px;box-shadow:0 4px 24px rgba(0,0,0,.06)">
          <h2 style="color:#003080;margin:0 0 12px">Souk Tchad</h2>
          <p style="color:#333;line-height:1.5">Bonjour,</p>
          <p style="color:#333;line-height:1.5">Voici votre code de validation pour créer votre compte :</p>
          <p style="font-size:36px;font-weight:700;letter-spacing:10px;color:#003080;margin:28px 0;text-align:center">${code}</p>
          <p style="color:#666;font-size:13px">Ce code expire dans <strong>10 minutes</strong>.</p>
          <p style="color:#999;font-size:12px;margin-top:24px">Si vous n'avez pas demandé ce code, ignorez ce message.</p>
        </div>
      </div>
    `;

    await this.send(email, `Souk Tchad — Code ${code}`, html);
  }

  async sendPaymentRequestNotification(data: {
    to: string;
    orderId: string;
    plan: string;
    amount: number;
    currency: string;
    providerLabel: string;
    payerPhone: string;
    userName: string;
    userEmail: string;
    proofImageUrl: string | null;
    appUrl: string;
  }): Promise<void> {
    const adminUrl = data.appUrl
      ? `${data.appUrl.replace(/\/$/, '')}/admin`
      : '';
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:560px;margin:0 auto;padding:24px">
        <h2 style="color:#003080">Souk Tchad — Nouveau paiement</h2>
        <p>Un client a soumis une demande d'abonnement payant.</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:14px">
          <tr><td style="padding:6px 0;color:#666">Client</td><td><strong>${data.userName}</strong> (${data.userEmail})</td></tr>
          <tr><td style="padding:6px 0;color:#666">Plan</td><td><strong>${data.plan}</strong></td></tr>
          <tr><td style="padding:6px 0;color:#666">Montant</td><td><strong>${data.amount} ${data.currency}</strong></td></tr>
          <tr><td style="padding:6px 0;color:#666">Opérateur</td><td>${data.providerLabel}</td></tr>
          <tr><td style="padding:6px 0;color:#666">N° payeur</td><td>${data.payerPhone}</td></tr>
          <tr><td style="padding:6px 0;color:#666">Référence</td><td style="font-family:monospace;font-size:12px">${data.orderId}</td></tr>
        </table>
        ${data.proofImageUrl ? `<p style="color:#666;font-size:13px">Capture d'écran jointe sur le serveur : ${data.proofImageUrl}</p>` : ''}
        ${adminUrl ? `<p style="margin:24px 0"><a href="${adminUrl}" style="background:#003080;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;display:inline-block">Ouvrir l'administration</a></p>` : ''}
        <p style="color:#999;font-size:12px">Confirmez ou refusez le paiement depuis l'application admin.</p>
      </div>
    `;
    await this.send(data.to, 'Souk Tchad — Nouveau paiement abonnement', html);
  }

  private async send(to: string, subject: string, html: string): Promise<void> {
    if (!this.transporter) {
      const isProd = this.configService.get<string>('NODE_ENV') === 'production';
      if (isProd) {
        throw new ServiceUnavailableException(
          'Envoi d\'e-mail indisponible : SMTP non configuré sur le serveur.',
        );
      }
      this.logger.warn(
        `SMTP non configuré — e-mail simulé pour ${to}: ${subject}`,
      );
      return;
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.configService.get<string>('smtp.from'),
        to,
        subject,
        html,
      });
      this.logger.log(`E-mail envoyé à ${to} (${info.messageId})`);
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Erreur SMTP inconnue';
      this.logger.error(`Échec envoi e-mail à ${to}: ${message}`);
      throw new ServiceUnavailableException(
        'Impossible d\'envoyer l\'e-mail. Vérifiez SMTP_USER / SMTP_PASS (mot de passe d\'application Gmail).',
      );
    }
  }
}
