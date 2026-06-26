import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { User } from '../../entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { CompleteRegistrationDto } from './dto/complete-registration.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('send-registration-otp')
  sendRegistrationOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendRegistrationOtp(dto);
  }

  @Post('verify-registration-otp')
  verifyRegistrationOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyRegistrationOtp(dto);
  }

  @Post('complete-registration')
  completeRegistration(@Body() dto: CompleteRegistrationDto) {
    return this.authService.completeRegistration(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('google')
  loginWithGoogle(@Body() dto: GoogleAuthDto) {
    return this.authService.loginWithGoogle(dto);
  }

  @Get('verify-email')
  async verifyEmail(@Query('token') token: string, @Res() res: Response) {
    try {
      const result = await this.authService.verifyEmail(token);
      res.type('html').send(this.verificationHtml(result.message, true));
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : 'Lien de vérification invalide ou expiré';
      res.status(400).type('html').send(this.verificationHtml(message, false));
    }
  }

  private verificationHtml(message: string, success: boolean) {
    const color = success ? '#0d7a3f' : '#b00020';
    const title = success ? 'Compte activé' : 'Vérification impossible';
    return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Souk Tchad — ${title}</title>
</head>
<body style="font-family:Arial,sans-serif;background:#f5f7fb;margin:0;padding:32px 16px">
  <div style="max-width:480px;margin:0 auto;background:#fff;border-radius:12px;padding:28px;box-shadow:0 4px 24px rgba(0,0,0,.08)">
    <h1 style="color:#003080;font-size:22px;margin:0 0 12px">Souk Tchad</h1>
    <p style="color:${color};font-weight:600">${title}</p>
    <p style="color:#333;line-height:1.5">${message}</p>
    <p style="color:#666;font-size:14px;margin-top:24px">Vous pouvez fermer cette page et ouvrir l'application Souk Tchad pour vous connecter.</p>
  </div>
</body>
</html>`;
  }

  @Post('resend-verification')
  resendVerification(@Body('email') email: string) {
    return this.authService.resendVerification(email);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: User) {
    return this.usersService.toPublic(user);
  }
}
