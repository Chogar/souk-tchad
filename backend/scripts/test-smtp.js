#!/usr/bin/env node
/**
 * Teste l'envoi SMTP Gmail (OTP).
 * Usage:
 *   node scripts/test-smtp.js
 *   node scripts/test-smtp.js destinataire@gmail.com
 */
const path = require('path');
const fs = require('fs');
const nodemailer = require('nodemailer');

function loadEnv(filePath) {
  if (!fs.existsSync(filePath)) return;
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (!(key in process.env)) process.env[key] = value;
  }
}

async function main() {
  const root = path.join(__dirname, '..');
  loadEnv(path.join(root, '.env'));

  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const user = (process.env.SMTP_USER || '').trim();
  const pass = (process.env.SMTP_PASS || '').trim();
  const from = process.env.SMTP_FROM || `Souk Tchad <${user}>`;
  const to = (process.argv[2] || user || '').trim();

  if (!user || !pass) {
    console.error('❌ SMTP_USER / SMTP_PASS manquants dans backend/.env');
    console.error('');
    console.error('1) Activez la validation en 2 étapes sur Gmail');
    console.error('2) Créez un mot de passe d\'application :');
    console.error('   https://myaccount.google.com/apppasswords');
    console.error('3) Dans backend/.env :');
    console.error('   SMTP_HOST=smtp.gmail.com');
    console.error('   SMTP_PORT=587');
    console.error('   SMTP_USER=votre@gmail.com');
    console.error('   SMTP_PASS=xxxx xxxx xxxx xxxx');
    console.error('   SMTP_FROM=Souk Tchad <votre@gmail.com>');
    process.exit(1);
  }

  if (!to) {
    console.error('❌ Indiquez un destinataire : node scripts/test-smtp.js email@gmail.com');
    process.exit(1);
  }

  const code = String(Math.floor(100000 + Math.random() * 900000));
  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
    ...(port === 587 ? { requireTLS: true } : {}),
  });

  console.log(`→ Connexion SMTP ${host}:${port} (${user})...`);
  await transporter.verify();
  console.log('✓ Connexion SMTP OK');

  console.log(`→ Envoi du code test ${code} à ${to}...`);
  const info = await transporter.sendMail({
    from,
    to,
    subject: `Souk Tchad — Code test ${code}`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:24px">
        <h2 style="color:#003080">Souk Tchad</h2>
        <p>Test SMTP réussi. Votre code de validation est :</p>
        <p style="font-size:32px;font-weight:700;letter-spacing:8px;color:#003080">${code}</p>
      </div>
    `,
  });

  console.log(`✅ E-mail envoyé (${info.messageId})`);
  console.log(`   Ouvrez Gmail → boîte de réception (ou Spam) de ${to}`);
}

main().catch((err) => {
  console.error('❌ Échec SMTP:', err.message || err);
  if (String(err.message || '').includes('Invalid login')) {
    console.error('');
    console.error('Astuce : utilisez un « mot de passe d\'application » Gmail,');
    console.error('pas le mot de passe normal du compte.');
    console.error('https://myaccount.google.com/apppasswords');
  }
  process.exit(1);
});
