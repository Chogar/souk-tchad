#!/bin/bash
# Initialise le schéma PostgreSQL en production depuis le terminal cPanel.
# Prérequis : .env configuré + npm run build déjà exécuté (via cpanel-run.sh).
#
# Usage :
#   bash scripts/cpanel-db-init.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/cpanel-env.sh"

INIT_JS="$BACKEND_DIR/dist/database/seeds/init-production-schema.js"

if [ ! -f "$INIT_JS" ]; then
  echo "❌ Fichier introuvable : $INIT_JS"
  echo "Compilez d'abord le backend :"
  echo "  bash scripts/cpanel-run.sh npm run build"
  exit 1
fi

if [ ! -f "$BACKEND_DIR/.env" ]; then
  echo "❌ Fichier .env manquant dans $BACKEND_DIR"
  echo "Créez-le à partir de .env.production.example puis relancez."
  exit 1
fi

echo "🚀 Initialisation du schéma production..."
node "$INIT_JS"
