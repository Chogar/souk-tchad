#!/usr/bin/env bash
# Génère mobile/dart_defines.json (API + Google OAuth) pour --dart-define-from-file.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
ENV_FILE="$MOBILE/.env"
DEFINES_FILE="$MOBILE/dart_defines.json"

MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")"
API_URL="${API_BASE_URL_OVERRIDE:-http://${MAC_IP}:3000/api}"

GOOGLE_CLIENT_ID=""
GOOGLE_SERVER_CLIENT_ID=""
if [[ -f "$ENV_FILE" ]]; then
  GOOGLE_CLIENT_ID="$(grep -E '^GOOGLE_CLIENT_ID=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r"' | xargs)"
  GOOGLE_SERVER_CLIENT_ID="$(grep -E '^GOOGLE_SERVER_CLIENT_ID=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r"' | xargs)"
fi

{
  printf '{\n  "API_BASE_URL": "%s"' "$API_URL"
  if [[ -n "$GOOGLE_CLIENT_ID" && "$GOOGLE_CLIENT_ID" != *"your-"* ]]; then
    printf ',\n  "GOOGLE_CLIENT_ID": "%s"' "$GOOGLE_CLIENT_ID"
  fi
  if [[ -n "$GOOGLE_SERVER_CLIENT_ID" && "$GOOGLE_SERVER_CLIENT_ID" != *"your-"* ]]; then
    printf ',\n  "GOOGLE_SERVER_CLIENT_ID": "%s"' "$GOOGLE_SERVER_CLIENT_ID"
  fi
  printf '\n}\n'
} > "$DEFINES_FILE"

echo "✓ dart_defines.json → API $API_URL"
