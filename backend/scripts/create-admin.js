#!/usr/bin/env node
/**
 * Crée ou promeut un compte ADMIN (accès CRUD /api/admin).
 *
 * Sur le serveur (terminal cPanel), depuis ~/souk-tchad/backend :
 *   bash scripts/cpanel-run.sh node scripts/create-admin.js <email> [motdepasse] [nom]
 *
 * Exemple :
 *   bash scripts/cpanel-run.sh node scripts/create-admin.js \
 *     souk.tchad.noreplay@gmail.com 'Tchad235@2026' 'Admin Souk'
 *
 * Lit DATABASE_* depuis backend/.env. N'utilise que pg + bcrypt (déjà installés).
 */
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function loadEnvFile() {
  const envPath = path.resolve(process.cwd(), '.env');
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) process.env[key] = value;
  }
}

async function main() {
  const [emailRaw, password, name] = process.argv.slice(2);
  const email = (emailRaw || '').trim().toLowerCase();
  if (!email || !email.includes('@')) {
    console.error(
      'Usage : node scripts/create-admin.js <email> [motdepasse] [nom]',
    );
    process.exit(1);
  }
  if (password && password.length < 8) {
    console.error('❌ Mot de passe trop court (8 caractères minimum).');
    process.exit(1);
  }

  loadEnvFile();

  const { Client } = require('pg');
  const bcrypt = require('bcrypt');

  const client = new Client({
    host: process.env.DATABASE_HOST || 'localhost',
    port: Number(process.env.DATABASE_PORT || 5432),
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
  });
  await client.connect();

  try {
    const existing = await client.query(
      'SELECT id, email, name, role FROM users WHERE email = $1',
      [email],
    );

    if (existing.rows.length > 0) {
      const user = existing.rows[0];
      const updates = ["role = 'ADMIN'", 'is_email_verified = true'];
      const params = [user.id];
      if (password) {
        params.push(await bcrypt.hash(password, 10));
        updates.push(`password_hash = $${params.length}`);
      }
      if (name) {
        params.push(name);
        updates.push(`name = $${params.length}`);
      }
      await client.query(
        `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $1`,
        params,
      );
      console.log(`✅ Compte existant promu ADMIN : ${user.email}`);
      if (password) console.log('   (mot de passe mis à jour)');
    } else {
      if (!password) {
        console.error(
          `❌ ${email} n'existe pas encore : fournissez un mot de passe pour le créer.`,
        );
        process.exit(1);
      }
      const passwordHash = await bcrypt.hash(password, 10);
      await client.query(
        `INSERT INTO users (id, email, name, password_hash, plan, role, is_email_verified)
         VALUES ($1, $2, $3, $4, 'PROFESSIONAL', 'ADMIN', true)`,
        [crypto.randomUUID(), email, name || 'Admin Souk', passwordHash],
      );
      console.log(`✅ Compte ADMIN créé : ${email}`);
    }

    const check = await client.query(
      'SELECT email, role, plan, is_email_verified FROM users WHERE email = $1',
      [email],
    );
    console.log('   Vérification :', check.rows[0]);
    console.log(
      '\n➡  Connectez-vous sur https://souk.experiencetech-td.com',
    );
    console.log('   puis Profil → Administration.');
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('❌ Erreur :', err.message || err);
  process.exit(1);
});
