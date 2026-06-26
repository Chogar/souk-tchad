#!/usr/bin/env bash
# Tests API automatisés — Phase 1 Souk Tchad
set -euo pipefail

MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")"
API="http://${MAC_IP}:3000/api"
PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
ko()   { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN + 1)); }

echo "══════════════════════════════════════════"
echo " Phase 1 — Tests API Souk Tchad"
echo " URL : $API"
echo "══════════════════════════════════════════"
echo ""

# 1. Serveur
echo "▸ Connectivité"
if curl -sf --connect-timeout 3 "$API/categories" >/dev/null; then
  ok "Backend joignable"
else
  ko "Backend injoignable — lancez : cd backend && npm run start:dev"
  exit 1
fi

# 2. Catégories
CAT_COUNT="$(curl -s "$API/categories" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")"
if [ "$CAT_COUNT" -ge 8 ]; then
  ok "Catégories : $CAT_COUNT"
else
  ko "Catégories insuffisantes : $CAT_COUNT (attendu ≥ 8)"
fi

# 3. Annonces
LISTINGS_JSON="$(curl -s "$API/listings")"
LISTING_COUNT="$(echo "$LISTINGS_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")"
DEMO_COUNT="$(echo "$LISTINGS_JSON" | python3 -c "import sys,json; print(sum(1 for x in json.load(sys.stdin) if x.get('title','').startswith('[Démo]')))")"

if [ "$LISTING_COUNT" -ge 15 ]; then
  ok "Annonces : $LISTING_COUNT (dont $DEMO_COUNT démo)"
else
  warn "Annonces : $LISTING_COUNT seulement — lancez : cd backend && npm run seed:dev"
fi

# 4. Recherche
SEARCH="$(curl -s "$API/listings?search=iphone" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")"
if [ "$SEARCH" -ge 1 ]; then
  ok "Recherche texte « iphone » : $SEARCH résultat(s)"
else
  warn "Recherche « iphone » : 0 résultat"
fi

# 5. Login
LOGIN_RESP="$(curl -s -X POST "$API/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"chogarfils3@gmail.com","password":"Hassouni1"}')"
TOKEN="$(echo "$LOGIN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('accessToken',''))" 2>/dev/null || echo "")"

if [ -n "$TOKEN" ]; then
  ok "Connexion test chogarfils3@gmail.com"
else
  ko "Échec login test — vérifiez seed:dev"
fi

# 6. Mes annonces (auth)
if [ -n "$TOKEN" ]; then
  MINE="$(curl -s "$API/listings/mine" -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")"
  ok "Mes annonces (auth) : $MINE"
fi

# 7. Favoris
if [ -n "$TOKEN" ]; then
  FAV_CODE="$(curl -s -o /dev/null -w "%{http_code}" "$API/favorites" -H "Authorization: Bearer $TOKEN")"
  if [ "$FAV_CODE" = "200" ]; then
    ok "Favoris (auth) : HTTP $FAV_CODE"
  else
    ko "Favoris : HTTP $FAV_CODE"
  fi
fi

# 8. Temps de réponse listings
START_MS="$(python3 -c "import time; print(int(time.time()*1000))")"
curl -sf "$API/listings" >/dev/null
END_MS="$(python3 -c "import time; print(int(time.time()*1000))")"
ELAPSED=$((END_MS - START_MS))
if [ "$ELAPSED" -lt 2000 ]; then
  ok "Temps /listings : ${ELAPSED} ms"
else
  warn "Temps /listings lent : ${ELAPSED} ms (> 2 s)"
fi

echo ""
echo "──────────────────────────────────────────"
echo " Résultat : $PASS OK | $FAIL échec(s) | $WARN avertissement(s)"
echo "──────────────────────────────────────────"
echo ""
echo "Sur iPhone : Profil → URL serveur → $API"
echo "Comptes test :"
echo "  chogarfils3@gmail.com / Hassouni1"
echo "  amina.test@souk-tchad.com / TestAmina1"
echo "  oumar@gmail.com / Oumar1"
echo ""

[ "$FAIL" -eq 0 ]
