#!/bin/bash
# Active l'environnement Node.js CloudLinux / cPanel (nodevenv).
# Usage : source scripts/cpanel-env.sh

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:-}"

if [ -z "$HOME_DIR" ]; then
  HOME_DIR="$(cd ~ && pwd)"
fi

activate_nodevenv() {
  local activate_file=""

  # Chemins typiques LWS : ~/nodevenv/souk-tchad/backend/20/bin/activate
  if [ -d "$HOME_DIR/nodevenv" ]; then
    activate_file="$(
      find "$HOME_DIR/nodevenv" -type f -path '*/bin/activate' 2>/dev/null \
        | grep -E 'souk-tchad|backend' \
        | sort \
        | tail -n 1 || true
    )"
    if [ -z "$activate_file" ]; then
      activate_file="$(
        find "$HOME_DIR/nodevenv" -type f -path '*/bin/activate' 2>/dev/null \
          | sort \
          | tail -n 1 || true
      )"
    fi
  fi

  if [ -n "$activate_file" ] && [ -f "$activate_file" ]; then
    # shellcheck disable=SC1090
    source "$activate_file"
    echo "✅ Node.js activé via : $activate_file"
    return 0
  fi

  return 1
}

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  if ! activate_nodevenv; then
    echo "❌ node/npm introuvable dans le PATH du terminal cPanel."
    echo ""
    echo "Faites d'abord ceci :"
    echo "  1. cPanel → Setup Node.js App → créez l'application (root = dossier backend)"
    echo "  2. Copiez la commande « Enter to the virtual environment » affichée par cPanel"
    echo "  3. Collez-la dans ce terminal, puis relancez votre commande"
    echo ""
    echo "Exemple typique :"
    echo "  source ~/nodevenv/souk-tchad/backend/20/bin/activate && cd ~/souk-tchad/backend"
    return 1 2>/dev/null || exit 1
  fi
fi

cd "$BACKEND_DIR"
echo "📂 Dossier : $BACKEND_DIR"
echo "🟢 node $(node -v)  |  npm $(npm -v)"
