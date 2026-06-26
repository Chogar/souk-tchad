#!/usr/bin/env bash
# Installe Souk Tchad sur iPhone via Wi‑Fi — sans câble USB après le premier appairage.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_ID="${1:-00008150-001128E83E42401C}"
DEFINES_FILE="$MOBILE/dart_defines.json"

bash "$ROOT/scripts/write-dart-defines.sh"
bash "$ROOT/scripts/sync-google-ios.sh" || true
API_URL="$(grep -E '"API_BASE_URL"' "$DEFINES_FILE" | sed 's/.*: "\(.*\)".*/\1/')"

GOOGLE_CLIENT_ID="$(grep -E '^GOOGLE_CLIENT_ID=' "$MOBILE/.env" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r"' | xargs || true)"
if [[ -z "$GOOGLE_CLIENT_ID" || "$GOOGLE_CLIENT_ID" == *"your-"* ]]; then
  echo ""
  echo "⚠️  Google Sign-In NON configuré (mobile/.env vide)."
  echo "   Remplissez GOOGLE_CLIENT_ID puis : bash scripts/setup-gmail-google.sh"
  echo ""
fi

echo "📱 Mode sans câble (Wi‑Fi)"
echo "   Appareil : $DEVICE_ID"
echo "   API Mac  : $API_URL"
echo ""
echo "Prérequis :"
echo "  • iPhone appairé en sans fil dans Xcode (Devices and Simulators)"
echo "  • Mac et iPhone sur le MÊME Wi‑Fi"
echo "  • Backend actif : cd backend && npm run start:dev"
echo ""

cd "$MOBILE"

# Ne pas faire « flutter devices | grep » (broken pipe). On capture d'abord la sortie.
echo "Recherche de l'iPhone (USB ou Wi‑Fi, ~20 s)..."
DEVICES_JSON="$(flutter devices --machine --device-timeout=20 2>/dev/null || echo '[]')"

device_found() {
  echo "$DEVICES_JSON" | grep -q "\"id\"[[:space:]]*:[[:space:]]*\"${DEVICE_ID}\""
}

if ! device_found; then
  # Secours : liste texte (sortie complète, pas de pipe vers grep)
  DEVICES_TEXT="$(flutter devices --device-timeout=20 2>/dev/null || true)"
  if ! echo "$DEVICES_TEXT" | grep -q "$DEVICE_ID"; then
    echo ""
    echo "⚠️  iPhone non détecté."
    echo "   1. Branchez une fois le câble"
    echo "   2. Xcode → Window → Devices → cochez « Connect via network »"
    echo "   3. Débranchez et relancez : bash install-sans-cable.sh"
    echo ""
    echo "   Ou installez avec câble : bash install-iphone.sh"
    exit 1
  fi
fi

echo "✓ iPhone trouvé."
echo ""

flutter build ios --dart-define-from-file="$DEFINES_FILE"
flutter install -d "$DEVICE_ID"

echo ""
echo "Lancement sur l'iPhone..."
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  com.hassanechogar.souktchad 2>/dev/null || true

echo ""
echo "✅ Installation terminée."
echo "   • Vous pouvez débrancher le câble USB"
echo "   • URL serveur dans l'app : $API_URL"
echo "   • Si besoin : Profil → Connexion serveur (sans câble)"
echo ""
