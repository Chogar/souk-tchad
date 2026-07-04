#!/bin/bash
# Lance une commande npm/node dans le terminal cPanel (active nodevenv automatiquement).
# Exemples :
#   bash scripts/cpanel-run.sh npm ci
#   bash scripts/cpanel-run.sh npm run build
#   bash scripts/cpanel-run.sh node dist/main.js

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/cpanel-env.sh"

if [ "$#" -eq 0 ]; then
  echo "Usage : bash scripts/cpanel-run.sh <commande> [args...]"
  echo "Ex.   : bash scripts/cpanel-run.sh npm ci"
  exit 1
fi

exec "$@"
