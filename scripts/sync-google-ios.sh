#!/usr/bin/env bash
# Configure Google Sign-In dans ios/Runner/Info.plist depuis mobile/.env
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/mobile/.env"
PLIST="$ROOT/mobile/ios/Runner/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "Info.plist introuvable : $PLIST"
  exit 1
fi

read_plist() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}

IOS_CLIENT_ID=""
REVERSED=""

if [[ -f "$ENV_FILE" ]]; then
  IOS_CLIENT_ID="$(grep -E '^GOOGLE_CLIENT_ID=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r"' | xargs)"
fi

FIREBASE_PLIST="$ROOT/mobile/ios/Runner/GoogleService-Info.plist"
if [[ (-z "$IOS_CLIENT_ID" || "$IOS_CLIENT_ID" == *"your-"*) && -f "$FIREBASE_PLIST" ]]; then
  IOS_CLIENT_ID="$(read_plist "$FIREBASE_PLIST" CLIENT_ID)"
  REVERSED="$(read_plist "$FIREBASE_PLIST" REVERSED_CLIENT_ID)"
  echo "ℹ️  IDs lus depuis GoogleService-Info.plist"
fi

if [[ -z "$IOS_CLIENT_ID" || "$IOS_CLIENT_ID" == *"your-"* || "$IOS_CLIENT_ID" == *"VOTRE-"* ]]; then
  echo "⚠️  GOOGLE_CLIENT_ID absent — Google Sign-In iOS non configuré."
  echo "   → bash scripts/apply-google-config.sh <ID_IOS> <ID_WEB>"
  exit 0
fi

if [[ -z "$REVERSED" ]]; then
  REVERSED="com.googleusercontent.apps.${IOS_CLIENT_ID%%.apps.googleusercontent.com}"
fi

/usr/libexec/PlistBuddy -c "Delete :GIDClientID" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GIDClientID string $IOS_CLIENT_ID" "$PLIST"

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleTypeRole string Editor" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED" "$PLIST"

echo "✓ Google Sign-In iOS configuré."
