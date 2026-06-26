#!/usr/bin/env bash
# Vérifie que Google Sign-In est prêt (mobile/.env + Info.plist + backend).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE_ENV="$ROOT/mobile/.env"
BACKEND_ENV="$ROOT/backend/.env"
PLIST="$ROOT/mobile/ios/Runner/Info.plist"
OK=1

read_env() {
  local file="$1" key="$2"
  if [[ -f "$file" ]]; then
    grep -E "^${key}=" "$file" | head -1 | cut -d= -f2- | tr -d '\r"' | xargs || true
  fi
}

IOS_ID="$(read_env "$MOBILE_ENV" GOOGLE_CLIENT_ID)"
WEB_MOBILE="$(read_env "$MOBILE_ENV" GOOGLE_SERVER_CLIENT_ID)"
WEB_BACKEND="$(read_env "$BACKEND_ENV" GOOGLE_CLIENT_ID)"

echo "═══ Vérification Google Sign-In ═══"
echo ""

if [[ -z "$IOS_ID" || "$IOS_ID" == *"your-"* ]]; then
  echo "❌ mobile/.env → GOOGLE_CLIENT_ID (client iOS) manquant"
  OK=0
else
  echo "✓ mobile/.env → GOOGLE_CLIENT_ID"
fi

if [[ -z "$WEB_MOBILE" || "$WEB_MOBILE" == *"your-"* ]]; then
  echo "❌ mobile/.env → GOOGLE_SERVER_CLIENT_ID (client Web) manquant"
  OK=0
else
  echo "✓ mobile/.env → GOOGLE_SERVER_CLIENT_ID"
fi

if [[ -z "$WEB_BACKEND" || "$WEB_BACKEND" == *"your-"* ]]; then
  echo "❌ backend/.env → GOOGLE_CLIENT_ID (client Web) manquant"
  OK=0
else
  echo "✓ backend/.env → GOOGLE_CLIENT_ID"
fi

if [[ -n "$WEB_MOBILE" && -n "$WEB_BACKEND" && "$WEB_MOBILE" != "$WEB_BACKEND" ]]; then
  echo "⚠️  Les ID Web mobile et backend devraient être identiques"
fi

if /usr/libexec/PlistBuddy -c "Print :GIDClientID" "$PLIST" &>/dev/null; then
  echo "✓ Info.plist → GIDClientID présent"
else
  echo "❌ Info.plist → GIDClientID absent (lancez: bash scripts/sync-google-ios.sh)"
  OK=0
fi

echo ""
if [[ $OK -eq 1 ]]; then
  echo "✅ Configuration Google OK — réinstallez : cd mobile && bash install-sans-cable.sh"
else
  echo "➡️  Guide : bash scripts/setup-gmail-google.sh"
  exit 1
fi
