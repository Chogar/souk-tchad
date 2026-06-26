import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { OAuth2Client } from 'google-auth-library';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { EmailToken } from '../../entities/email-token.entity';
import { RegistrationOtp } from '../../entities/registration-otp.entity';
import { MailService } from '../mail/mail.service';
import { UsersService } from '../users/users.service';
import { CompleteRegistrationDto } from './dto/complete-registration.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly googleClient: OAuth2Client;

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
    @InjectRepository(EmailToken)
    private readonly emailTokensRepository: Repository<EmailToken>,
    @InjectRepository(RegistrationOtp)
    private readonly registrationOtpRepository: Repository<RegistrationOtp>,
  ) {
    this.googleClient = new OAuth2Client(
      this.configService.get<string>('google.clientId'),
    );
  }

  /** En dev sans SMTP Gmail, on active le compte tout de suite. */
  private skipsEmailVerification(): boolean {
    const isProd = this.configService.get<string>('NODE_ENV') === 'production';
    if (isProd) return false;
    const smtpUser = this.configService.get<string>('smtp.user')?.trim();
    return !smtpUser;
  }

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.usersService.findByEmail(email);
    if (existing) {
      if (!existing.isEmailVerified) {
        await this.sendVerificationEmail(existing.id, existing.email);
        return {
          message:
            'Ce compte existe déjà mais n\'est pas vérifié. Un nouvel e-mail de validation a été envoyé.',
          email: existing.email,
        };
      }
      throw new ConflictException(
        'Cet e-mail est déjà utilisé. Connectez-vous ou utilisez Google.',
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.usersService.createWithPassword({
      email,
      name: dto.name,
      passwordHash,
    });

    if (this.skipsEmailVerification()) {
      await this.usersService.verifyEmail(user.id);
      return {
        message: 'Compte créé. Vous pouvez vous connecter.',
        email: user.email,
      };
    }

    await this.sendVerificationEmail(user.id, user.email);

    return {
      message:
        'Compte créé. Vérifiez votre e-mail Gmail pour activer votre compte.',
      email: user.email,
    };
  }

  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.usersService.findByEmail(email);
    if (!user?.passwordHash) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    if (!user.isEmailVerified) {
      if (this.skipsEmailVerification()) {
        await this.usersService.verifyEmail(user.id);
      } else {
        throw new UnauthorizedException(
          'E-mail non vérifié. Consultez votre boîte Gmail.',
        );
      }
    }

    return this.buildAuthResponse(user);
  }

  async loginWithGoogle(dto: GoogleAuthDto) {
    const webClientId = this.configService.get<string>('google.clientId');
    const iosClientId = this.configService.get<string>('google.iosClientId');
    if (!webClientId) {
      throw new UnauthorizedException('Google OAuth non configuré');
    }

    const audiences = [webClientId, iosClientId].filter(
      (id): id is string => !!id?.trim(),
    );

    let payload;
    try {
      const ticket = await this.googleClient.verifyIdToken({
        idToken: dto.idToken,
        audience: audiences.length === 1 ? audiences[0] : audiences,
      });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Token Google invalide ou expiré');
    }

    if (!payload?.email || !payload.sub) {
      throw new UnauthorizedException('Token Google invalide');
    }

    const email = payload.email.trim().toLowerCase();

    let user =
      (await this.usersService.findByGoogleId(payload.sub)) ??
      (await this.usersService.findByEmail(email));

    if (user && !user.googleId) {
      user = await this.usersService.linkGoogleAccount(user, {
        googleId: payload.sub,
        avatarUrl: payload.picture,
      });
    } else if (!user) {
      user = await this.usersService.createFromGoogle({
        email,
        name: payload.name ?? email.split('@')[0],
        googleId: payload.sub,
        avatarUrl: payload.picture,
      });
    }

    return this.buildAuthResponse(user);
  }

  async verifyEmail(token: string) {
    const emailToken = await this.emailTokensRepository.findOne({
      where: { token },
      relations: { user: true },
    });

    if (!emailToken || emailToken.expiresAt < new Date()) {
      throw new BadRequestException('Lien de vérification invalide ou expiré');
    }

    await this.usersService.verifyEmail(emailToken.userId);
    await this.emailTokensRepository.remove(emailToken);

    return { message: 'E-mail vérifié avec succès. Vous pouvez vous connecter.' };
  }

  async sendRegistrationOtp(dto: SendOtpDto) {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.usersService.findByEmail(email);
    if (existing?.isEmailVerified) {
      throw new ConflictException(
        'Cet e-mail est déjà utilisé. Connectez-vous ou utilisez Google.',
      );
    }

    await this.registrationOtpRepository.delete({ email });

    const code = String(Math.floor(100000 + Math.random() * 900000));
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await this.registrationOtpRepository.save(
      this.registrationOtpRepository.create({ email, code, expiresAt }),
    );

    await this.mailService.sendRegistrationOtpEmail(email, code);

    const response: { message: string; email: string; devCode?: string } = {
      message: 'Un code à 6 chiffres a été envoyé sur votre Gmail.',
      email,
    };

    if (this.skipsEmailVerification()) {
      this.logger.warn(`[DEV] OTP inscription ${email}: ${code}`);
      response.devCode = code;
      response.message =
        'Mode dev : SMTP non configuré. Utilisez le code affiché ci-dessous.';
    }

    return response;
  }

  async verifyRegistrationOtp(dto: VerifyOtpDto) {
    const email = dto.email.trim().toLowerCase();
    const otp = await this.registrationOtpRepository.findOne({
      where: { email },
      order: { createdAt: 'DESC' },
    });

    if (!otp || otp.expiresAt < new Date()) {
      throw new BadRequestException('Code expiré ou invalide. Demandez un nouveau code.');
    }

    if (otp.code !== dto.code) {
      throw new BadRequestException('Code incorrect.');
    }

    const registrationToken = uuidv4();
    const tokenExpiresAt = new Date(Date.now() + 30 * 60 * 1000);

    otp.registrationToken = registrationToken;
    otp.tokenExpiresAt = tokenExpiresAt;
    await this.registrationOtpRepository.save(otp);

    return {
      message: 'E-mail validé. Complétez votre profil.',
      email,
      registrationToken,
    };
  }

  async completeRegistration(dto: CompleteRegistrationDto) {
    const email = dto.email.trim().toLowerCase();
    const otp = await this.registrationOtpRepository.findOne({
      where: { email, registrationToken: dto.registrationToken },
    });

    if (
      !otp?.registrationToken ||
      !otp.tokenExpiresAt ||
      otp.tokenExpiresAt < new Date()
    ) {
      throw new BadRequestException(
        'Session d\'inscription expirée. Recommencez depuis le début.',
      );
    }

    const existing = await this.usersService.findByEmail(email);
    if (existing?.isEmailVerified) {
      throw new ConflictException('Cet e-mail est déjà utilisé.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = existing
      ? await this.usersService.finalizePasswordRegistration(existing.id, {
          name: dto.name,
          phone: dto.phone,
          passwordHash,
        })
      : await this.usersService.createWithPassword({
          email,
          name: dto.name,
          passwordHash,
          phone: dto.phone,
          isEmailVerified: true,
        });

    await this.registrationOtpRepository.delete({ email });

    return this.buildAuthResponse(user);
  }

  async resendVerification(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || user.isEmailVerified) {
      return { message: 'Si le compte existe, un e-mail a été envoyé.' };
    }

    await this.sendVerificationEmail(user.id, user.email);
    return { message: 'E-mail de vérification renvoyé.' };
  }

  private async sendVerificationEmail(userId: string, email: string) {
    await this.emailTokensRepository.delete({ userId });

    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await this.emailTokensRepository.save(
      this.emailTokensRepository.create({ userId, token, expiresAt }),
    );

    await this.mailService.sendVerificationEmail(email, token);
  }

  private buildAuthResponse(user: {
    id: string;
    email: string;
    name: string;
    avatarUrl: string | null;
    plan: string;
    isEmailVerified: boolean;
    createdAt: Date;
  }) {
    const accessToken = this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });

    return {
      accessToken,
      user: this.usersService.toPublic(user as never),
    };
  }
}
