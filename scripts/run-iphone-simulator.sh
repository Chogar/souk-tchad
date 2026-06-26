#!/bin/bash
set -e

SIMULATOR_ID="${SIMULATOR_ID:-110C5533-2CB9-488D-B42F-0D14EFB6D527}" # iPhone 17 Pro Max iOS 26.5
API_URL="${API_BASE_URL:-http://127.0.0.1:3000/api}"

echo "📱 Démarrage iPhone 17 Pro Max (iOS 26.5)..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$SIMULATOR_ID" -b

echo "🚀 Lancement Souk Tchad..."
cd "$(dirname "$0")/../mobile"
flutter run -d "$SIMULATOR_ID" --dart-define=API_BASE_URL="$API_URL"
