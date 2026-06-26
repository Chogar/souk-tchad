#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_ID="${1:-00008150-001128E83E42401C}"
DEFINES_FILE="$MOBILE/dart_defines.json"

bash "$ROOT/scripts/write-dart-defines.sh"
API_URL="$(grep -E '"API_BASE_URL"' "$DEFINES_FILE" | sed 's/.*: "\(.*\)".*/\1/')"

echo "📱 Appareil : $DEVICE_ID"
echo "🌐 API      : $API_URL"
echo ""
echo "Assurez-vous que :"
echo "  • L'iPhone est branché et déverrouillé"
echo "  • Xcode → Réglages → Comptes → votre Apple ID est ajouté"
echo "  • Runner → Signing → Automatically manage signing (équipe 5674YG4G5N)"
echo "  • iPhone et Mac sont sur le même Wi‑Fi"
echo ""
echo "Sans cable apres install : bash install-iphone.sh"
echo "Apres lancement debug : touche d puis debranchez le cable"
echo ""

cd "$MOBILE"

if [ "${STANDALONE:-}" = "1" ]; then
  exec "$ROOT/scripts/install-physical-iphone.sh" "$DEVICE_ID"
fi

flutter run \
  -d "$DEVICE_ID" \
  --dart-define-from-file="$DEFINES_FILE"
