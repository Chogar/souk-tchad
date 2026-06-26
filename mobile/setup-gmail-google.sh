#!/usr/bin/env bash
# Lance la configuration Gmail + Google depuis le dossier mobile/.
exec "$(cd "$(dirname "$0")/.." && pwd)/scripts/setup-gmail-google.sh" "$@"
