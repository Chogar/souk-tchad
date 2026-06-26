#!/usr/bin/env bash
# Installe Souk Tchad sur l'iPhone — fonctionne SANS câble après installation (Wi‑Fi).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
DEVICE_ID="${1:-00008150-001128E83E42401C}"
DEFINES_FILE="$MOBILE/dart_defines.json"

bash "$ROOT/scripts/write-dart-defines.sh"
bash "$ROOT/scripts/sync-google-ios.sh" || true
API_URL="$(grep -E '"API_BASE_URL"' "$DEFINES_FILE" | sed 's/.*: "\(.*\)".*/\1/')"

echo "📱 Appareil : $DEVICE_ID"
echo "🌐 API Wi‑Fi : $API_URL"
echo ""
echo "Compilation et installation (mode autonome, sans session debug)..."
echo ""

cd "$MOBILE"
flutter build ios --dart-define-from-file="$DEFINES_FILE"
flutter install -d "$DEVICE_ID"

echo ""
echo "Lancement sur l'iPhone..."
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  com.hassanechogar.souktchad 2>/dev/null || true

echo ""
echo "✅ Souk Tchad est installée."
echo "   • Vous pouvez DÉBRANCHER le câble USB"
echo "   • Mac et iPhone sur le MÊME Wi‑Fi"
echo "   • Backend actif sur le port 3000"
echo "   • Ouvrez l'app depuis l'icône si besoin"
echo ""
echo "   Mise à jour sans câble (Wi‑Fi) : bash install-sans-cable.sh"
echo "   Hot reload (dev) : bash run-physical-iphone.sh"
