#!/usr/bin/env bash
# Aide à la configuration Gmail SMTP + Google Sign-In pour Souk Tchad
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_ENV="$ROOT/backend/.env"
MOBILE_ENV="$ROOT/mobile/.env"
MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")"

if [[ ! -f "$MOBILE_ENV" ]]; then
  cp "$ROOT/mobile/.env.example" "$MOBILE_ENV"
  echo "✓ Fichier créé : mobile/.env"
fi

echo "═══════════════════════════════════════════════════"
echo "  Souk Tchad — Configuration Gmail + Google"
echo "═══════════════════════════════════════════════════"
echo ""
echo "1) Console Google Cloud : https://console.cloud.google.com/"
echo "   • Créer un projet"
echo "   • APIs et services → Écran de consentement OAuth"
echo "   • Identifiants → Créer :"
echo "     - Application Web  → GOOGLE_SERVER_CLIENT_ID (backend + Android)"
echo "     - Application iOS  → bundle com.hassanechogar.souktchad"
echo ""
echo "2) Gmail — mot de passe d'application :"
echo "   https://myaccount.google.com/apppasswords"
echo "   (validation en 2 étapes obligatoire)"
echo ""
echo "3) Renseigner backend/.env :"
echo "   SMTP_HOST=smtp.gmail.com"
echo "   SMTP_PORT=587"
echo "   SMTP_USER=votre@gmail.com"
echo "   SMTP_PASS=xxxx xxxx xxxx xxxx"
echo "   SMTP_FROM=Souk Tchad <votre@gmail.com>"
echo "   GOOGLE_CLIENT_ID=<ID client Web>.apps.googleusercontent.com"
echo "   APP_URL=http://${MAC_IP}:3000"
echo ""
echo "4) Renseigner mobile/.env :"
echo "   GOOGLE_CLIENT_ID=<ID client iOS>.apps.googleusercontent.com"
echo "   GOOGLE_SERVER_CLIENT_ID=<ID client Web>.apps.googleusercontent.com"
echo ""
read -r -p "Appuyez sur Entrée quand les fichiers .env sont remplis..."

bash "$ROOT/scripts/sync-google-ios.sh" || true
bash "$ROOT/scripts/check-google-config.sh" || true

echo ""
echo "5) Redémarrer le backend : cd backend && npm run start:dev"
echo "6) Réinstaller l'app : cd mobile && bash install-sans-cable.sh"
echo ""
echo "✅ Terminé."
