# Remise à niveau production — suite « fait tous »

## Livré

### Backend
- Pages légales servies : `GET {APP_URL}/legal/privacy.html` et `/legal/terms.html`
- Paiement Mobile Money **manuel** :
  - `POST /api/subscriptions/checkout` → ordre PENDING + instructions
  - `POST /api/subscriptions/confirm-payment` `{ orderId, secret }` → active le plan
  - Variables : `PAYMENT_MODE`, `PAYMENT_WEBHOOK_SECRET`, `PAYMENT_MOMO_NUMBER`
- Migrations SQL : `001_performance_indexes.sql`, `002_payment_orders.sql`
- `.env.production.example` à jour (CORS + paiements)

### Mobile
- Checkout UI (profil + abonnements) pour plans payants
- AdMob via dart-define (`ADMOB_*`)
- URLs privacy/CGU = API `/legal/...` par défaut
- Scripts Windows :
  - `scripts/write-dart-defines.ps1`
  - `scripts/generate-android-keystore.ps1` (à lancer une fois)
  - `scripts/build-release.ps1`

## Actions manuelles restantes (comptes / serveur)

1. **Keystore** : `powershell -File scripts/generate-android-keystore.ps1`
2. **Firebase** : déposer `google-services.json` + `GoogleService-Info.plist`
3. **AdMob** : IDs réels dans `mobile/.env.production`
4. **Déployer backend** LWS avec `.env` prod + `npm run build && npm run start:prod`
5. **Confirmer un paiement** :
   ```bash
   curl -X POST https://API/api/subscriptions/confirm-payment \
     -H "Content-Type: application/json" \
     -d '{"orderId":"...","secret":"PAYMENT_WEBHOOK_SECRET"}'
   ```
6. **iOS** : `flutter build ipa --dart-define-from-file=dart_defines.json` (sur macOS)
