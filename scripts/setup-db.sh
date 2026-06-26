#!/bin/bash
# Initialise PostgreSQL pour le développement local (macOS/Homebrew ou Docker)

set -e

DB_USER="${DATABASE_USER:-souk_tchad}"
DB_PASS="${DATABASE_PASSWORD:-souk_tchad_dev}"
DB_NAME="${DATABASE_NAME:-souk_tchad}"

echo "🔧 Configuration PostgreSQL pour Souk Tchad..."

if command -v docker &>/dev/null && docker compose ps postgres 2>/dev/null | grep -q "running\|Up"; then
  echo "✅ PostgreSQL Docker déjà actif"
  exit 0
fi

if command -v psql &>/dev/null; then
  psql postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
    psql postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

  psql postgres -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
    psql postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

  psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true
  echo "✅ Base locale prête : $DB_NAME (user: $DB_USER)"
else
  echo "❌ PostgreSQL non trouvé. Installez-le ou lancez : docker compose up -d"
  exit 1
fi
