#!/usr/bin/env bash
# Applique les identifiants Google OAuth partout (une commande).
# Usage : bash scripts/apply-google-config.sh IOS_CLIENT_ID WEB_CLIENT_ID
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: bash scripts/apply-google-config.sh <ID_CLIENT_IOS> <ID_CLIENT_WEB>"
  echo "Exemple:"
  echo "  bash scripts/apply-google-config.sh \\"
  echo "    123456-ios.apps.googleusercontent.com \\"
  echo "    123456-web.apps.googleusercontent.com"
  exit 1
fi

IOS_ID="$1"
WEB_ID="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE_ENV="$ROOT/mobile/.env"
BACKEND_ENV="$ROOT/backend/.env"
MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")"

if [[ "$IOS_ID" == *"your-"* || "$WEB_ID" == *"your-"* ||
      "$IOS_ID" == *"VOTRE-"* || "$WEB_ID" == *"VOTRE-"* ||
      "$IOS_ID" == *"abc12def"* || "$WEB_ID" == *"xyz99web"* ||
      "$IOS_ID" != *".apps.googleusercontent.com" ]]; then
  echo "❌ Ces identifiants sont des EXEMPLES de la documentation, pas les vôtres."
  echo ""
  echo "   Allez sur https://console.cloud.google.com/apis/credentials"
  echo "   → Créer un ID client iOS (bundle com.hassanechogar.souktchad)"
  echo "   → Créer un ID client Web"
  echo "   → Copiez les VRAIS IDs affichés par Google (autres chiffres/lettres)."
  echo ""
  echo "   Puis relancez :"
  echo "   bash scripts/apply-google-config.sh <ID_iOS_copié> <ID_Web_copié>"
  exit 1
fi

# mobile/.env
if [[ ! -f "$MOBILE_ENV" ]]; then
  cp "$ROOT/mobile/.env.example" "$MOBILE_ENV"
fi

set_env() {
  local file="$1" key="$2" value="$3"
  if grep -q "^${key}=" "$file"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

set_env "$MOBILE_ENV" GOOGLE_CLIENT_ID "$IOS_ID"
set_env "$MOBILE_ENV" GOOGLE_SERVER_CLIENT_ID "$WEB_ID"

# backend/.env
set_env "$BACKEND_ENV" GOOGLE_CLIENT_ID "$WEB_ID"
set_env "$BACKEND_ENV" GOOGLE_IOS_CLIENT_ID "$IOS_ID"
if ! grep -q '^APP_URL=' "$BACKEND_ENV"; then
  echo "APP_URL=http://${MAC_IP}:3000" >> "$BACKEND_ENV"
else
  sed -i '' "s|^APP_URL=.*|APP_URL=http://${MAC_IP}:3000|" "$BACKEND_ENV"
fi

bash "$ROOT/scripts/sync-google-ios.sh"

# meta Google Sign-In pour le web
INDEX_HTML="$ROOT/mobile/web/index.html"
if [[ -f "$INDEX_HTML" ]]; then
  if grep -q 'name="google-signin-client_id"' "$INDEX_HTML"; then
    sed -i '' "s|content=\"[^\"]*apps.googleusercontent.com\"|content=\"${WEB_ID}\"|" "$INDEX_HTML"
  else
    sed -i '' "s|<meta name=\"theme-color\"|<meta name=\"google-signin-client_id\" content=\"${WEB_ID}\">\\n  <meta name=\"theme-color\"|" "$INDEX_HTML"
  fi
  echo "✓ web/index.html → google-signin-client_id"
fi

echo ""
echo "✅ Google configuré."
echo "   iOS  : $IOS_ID"
echo "   Web  : $WEB_ID"
echo ""
echo "Prochaines étapes :"
echo "  1) Redémarrer le backend : cd backend && npm run start:dev"
echo "  2) Réinstaller l'app     : cd mobile && bash install-sans-cable.sh"
