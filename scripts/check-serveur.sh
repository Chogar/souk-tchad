#!/usr/bin/env bash
# Vérifie que le backend est joignable depuis le réseau local (iPhone).
set -euo pipefail

MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")"
API_URL="http://${MAC_IP:-127.0.0.1}:3000/api"

echo "🔍 Diagnostic serveur Souk Tchad"
echo "   IP Mac (Wi‑Fi) : ${MAC_IP:-non détectée}"
echo "   URL iPhone     : $API_URL"
echo ""

if lsof -nP -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "✓ Port 3000 : backend en écoute"
else
  echo "✗ Port 3000 : RIEN n'écoute → lancez : cd backend && npm run start:dev"
  exit 1
fi

HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$API_URL/categories" || echo "000")"
if [ "$HTTP_CODE" = "200" ]; then
  echo "✓ API /categories : HTTP $HTTP_CODE"
else
  echo "✗ API /categories : HTTP $HTTP_CODE (échec)"
  exit 1
fi

echo ""
echo "✅ Le Mac est prêt. Sur l'iPhone :"
echo "   Profil → Connexion serveur → $API_URL"
echo "   Réglages → Souk Tchad → Réseau local = activé"
