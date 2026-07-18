#!/usr/bin/env bash
# Cache-busting du build web Flutter (mobile/build/web) :
# renomme main.dart.js et flutter_bootstrap.js avec un horodatage et met à
# jour toutes les références (index.html, service worker).
# Nécessaire car les anciens builds étaient servis avec
# Cache-Control immutable 1 an : sans renommage, les navigateurs des
# visiteurs ne rechargeraient jamais le nouveau code.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/mobile/build/web"
STAMP="${1:-$(date +%Y%m%d%H%M%S)}"

cd "$WEB"
if [[ ! -f main.dart.js || ! -f flutter_bootstrap.js ]]; then
  echo "❌ Build web introuvable ou déjà horodaté ($WEB)" >&2
  exit 1
fi

# Purger les fichiers horodatés d'un build précédent
rm -f main.dart.2*.js flutter_bootstrap.2*.js

MAIN="main.dart.$STAMP.js"
BOOT="flutter_bootstrap.$STAMP.js"

mv main.dart.js "$MAIN"
mv flutter_bootstrap.js "$BOOT"

# macOS (BSD sed) : -i ''
sed -i '' "s|main\.dart\.js|$MAIN|g" "$BOOT" flutter_service_worker.js
sed -i '' "s|flutter_bootstrap\.js|$BOOT|g" index.html flutter_service_worker.js

echo "✓ Cache-busting : $MAIN + $BOOT (références mises à jour)"
