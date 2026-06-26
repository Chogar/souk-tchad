# Souk Tchad — Guide agent Cursor

Marketplace Flutter + NestJS pour le Tchad. Monorepo : `backend/`, `mobile/`, `scripts/`, `docs/`.

## Stack

| Couche | Techno |
|--------|--------|
| API | NestJS, TypeORM, PostgreSQL, Socket.io |
| Mobile / Web | Flutter 3.41+, Riverpod, go_router |
| Auth | JWT, Google OAuth, inscription OTP e-mail (6 chiffres) |
| IA | Gemini (traduction, amélioration annonces) |
| Cache mobile | SQLite (iOS/Android), mémoire (web) |

## Commandes utiles

```bash
npm run db:setup          # PostgreSQL local
npm run backend:dev       # API :3000
npm run seed:dev          # 100 annonces démo + comptes test
npm run seed:dev:reset    # Reset annonces démo
npm run test:phase1       # Tests API

# Mobile — toujours générer dart_defines avant run
bash scripts/write-dart-defines.sh
cd mobile && flutter run --dart-define-from-file=dart_defines.json

# iPhone physique
bash scripts/run-physical-iphone.sh
bash scripts/install-sans-cable.sh

# Web (Chrome)
API_BASE_URL_OVERRIDE=http://localhost:3000/api bash scripts/write-dart-defines.sh
cd mobile && flutter run -d chrome --dart-define-from-file=dart_defines.json
```

## Conventions code

- Répondre en **français** à l'utilisateur.
- Diff minimal : ne pas refactorer hors scope.
- Ne jamais committer `.env`, `dart_defines.json`, `backend/dist/`, `*.zip`.
- `API_BASE_URL` injecté via `--dart-define-from-file=dart_defines.json` (pas seul `.env` mobile).
- iPhone physique : IP Mac Wi‑Fi dans `write-dart-defines.sh`, pas `localhost`.
- Web : grille accueil **6 colonnes** (`kIsWeb`), mobile **3 colonnes**.

## Fichiers sensibles (hors Git)

Demander au lead (Hassane) les vrais fichiers `.env` :

- `backend/.env` — DB, JWT, Google, SMTP, Gemini, Firebase
- `mobile/.env` — `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`

## Modules récents (juin 2026)

- Inscription OTP : `RegisterScreen` → `RegisterOtpScreen` → `RegisterProfileScreen`
- Suppression compte : `DELETE /api/users/me`, bouton profil mobile
- 100 annonces démo : `backend/src/database/seeds/demo-listings.catalog.ts`
- Cache web sans SQLite : `mobile/lib/core/services/cache_service.dart` (`kIsWeb`)
- Aperçu marketing : `docs/apercu/index.html`

## Pièges connus

| Problème | Cause | Fix |
|----------|-------|-----|
| Google Sign-In échoue | IDs pas dans dart_defines | `bash scripts/write-dart-defines.sh` |
| OTP visible dans l'app | SMTP non configuré | Normal en dev ; configurer `SMTP_*` en prod |
| Port 3000 occupé | Backend déjà lancé | Ne pas relancer |
| Refresh catalogue en boucle | Corrigé — ne pas réintroduire `bumpCatalogVersion` en sync arrière-plan |
| Web crash SQLite | Utiliser cache mémoire `kIsWeb` | Déjà en place |

## Documentation

- [docs/COLLABORATEUR-CURSOR.md](docs/COLLABORATEUR-CURSOR.md) — onboarding équipe
- [docs/HISTORIQUE-PROJET.md](docs/HISTORIQUE-PROJET.md) — décisions et historique
- [docs/PHASE1-TEST-IPHONE.md](docs/PHASE1-TEST-IPHONE.md) — tests iPhone
- [docs/apercu/index.html](docs/apercu/index.html) — démo visuelle

## Roadmap (non fait)

1. Tests iPhone complets
2. Services externes prod (SMTP, Firebase, AdMob release)
3. Builds release Android/iOS
4. VPS LWS + SSL
5. Paiements stores
