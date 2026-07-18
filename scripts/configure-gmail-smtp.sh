#!/usr/bin/env bash
# Configure Gmail SMTP pour envoyer les OTP sur Gmail.
# Usage:
#   bash scripts/configure-gmail-smtp.sh votre@gmail.com "xxxx xxxx xxxx xxxx"
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/backend/.env"

GMAIL="${1:-}"
APP_PASS="${2:-}"

if [[ -z "$GMAIL" || -z "$APP_PASS" ]]; then
  echo "═══════════════════════════════════════════════════"
  echo "  Souk Tchad — OTP par Gmail (SMTP)"
  echo "═══════════════════════════════════════════════════"
  echo ""
  echo "1) Sur https://myaccount.google.com/security"
  echo "   → activez la validation en 2 étapes"
  echo ""
  echo "2) Créez un mot de passe d'application :"
  echo "   https://myaccount.google.com/apppasswords"
  echo "   (Application : Mail / Autre → Souk Tchad)"
  echo ""
  echo "3) Relancez :"
  echo "   bash scripts/configure-gmail-smtp.sh votre@gmail.com \"xxxx xxxx xxxx xxxx\""
  echo ""
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Fichier introuvable : $ENV_FILE"
  exit 1
fi

upsert() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    # macOS / BSD sed
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  elif grep -q "^# ${key}=" "$ENV_FILE"; then
    sed -i.bak "s|^# ${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# Nettoie les lignes commentées SMTP courantes
sed -i.bak \
  -e 's|^# SMTP_HOST=.*||' \
  -e 's|^# SMTP_PORT=.*||' \
  -e 's|^# SMTP_USER=.*||' \
  -e 's|^# SMTP_PASS=.*||' \
  -e 's|^# SMTP_FROM=.*||' \
  "$ENV_FILE"

upsert "SMTP_HOST" "smtp.gmail.com"
upsert "SMTP_PORT" "587"
upsert "SMTP_USER" "$GMAIL"
upsert "SMTP_PASS" "$APP_PASS"
upsert "SMTP_FROM" "Souk Tchad <${GMAIL}>"

rm -f "${ENV_FILE}.bak"
# Nettoie lignes vides en double
awk 'NF || !blank++ { if (NF) blank=0; print }' "$ENV_FILE" > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"

echo "✓ SMTP Gmail écrit dans backend/.env"
echo ""
echo "Test d'envoi :"
echo "  cd backend && node scripts/test-smtp.js $GMAIL"
echo ""
echo "Puis redémarrez le backend :"
echo "  cd backend && npm run start:dev"
echo ""
echo "À l'inscription, le code OTP arrivera dans Gmail (vérifiez aussi Spam)."
