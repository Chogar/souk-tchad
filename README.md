# Souk Tchad — Chad Market

Marketplace de petites annonces pour le Tchad. Monorepo à coûts fixes (VPS LWS).

## Structure

```
Souk Tchad/
├── backend/          # API NestJS + PostgreSQL + Socket.io
├── mobile/           # App Flutter (Android, iOS, Web)
├── scripts/          # setup-db.sh
├── docker-compose.yml
└── README.md
```

## Fonctionnalités implémentées

| Module | Backend | Mobile |
|--------|---------|--------|
| Auth Google + e-mail | ✅ | ✅ |
| Validation e-mail SMTP | ✅ | ✅ |
| 8 catégories + annonces | ✅ | ✅ |
| Modération locale | ✅ | — |
| Favoris | ✅ | ✅ |
| Chat temps réel (Socket.io) | ✅ | ✅ |
| Abonnements (4 plans) | ✅ | ✅ |
| IA Gemini (traduction, amélioration) | ✅ | ✅ |
| Notifications FCM | ✅ | ✅ (fichiers Firebase requis) |
| AdMob (plan gratuit) | — | ✅ |
| Offline SQLite (cache) | — | ✅ |
| Compression images | — | ✅ |

> **Paiement réel** et **déploiement LWS** : à faire en dernière étape.

## Prérequis

- Node.js 20+
- Flutter 3.41+
- PostgreSQL (local ou Docker)

## Démarrage

### 1. Base de données

```bash
# Option A : PostgreSQL local (macOS)
npm run db:setup

# Option B : Docker
docker compose up -d
```

### 2. Backend

```bash
cd backend
cp .env.example .env
npm install
npm run start:dev
```

API : `http://localhost:3000/api`  
WebSocket chat : `ws://localhost:3000/chat`

### 3. Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

> Sur émulateur Android : `10.0.2.2` = localhost. Sur appareil physique : IP de votre machine.

## Configuration (avant production)

| Variable | Description |
|----------|-------------|
| `GOOGLE_CLIENT_ID` | OAuth Google |
| `SMTP_*` | E-mail LWS |
| `GEMINI_API_KEY` | IA gratuite |
| `FIREBASE_*` | Notifications push (backend) |
| `GoogleService-Info.plist` | iOS — `mobile/ios/Runner/` |
| `google-services.json` | Android — `mobile/android/app/` |
| AdMob ID | `ad_banner.dart` (production) |

## Roadmap — Déploiement (phase finale)

1. Configurer VPS LWS (Node.js, PostgreSQL, Nginx)
2. Certificat SSL + domaine
3. Variables d'environnement production
4. Intégrer paiement mobile (Google Play / App Store)
5. Build release Android/iOS
6. Monitoring et sauvegardes BDD

## Scripts racine

```bash
npm run db:setup       # Créer user/DB PostgreSQL local
npm run backend:dev    # Lancer l'API
npm run seed:dev         # Comptes + 100 annonces [Démo]
npm run test:phase1      # Tests API automatisés (phase 1)
npm run mobile:analyze # Analyser Flutter
```

Checklist tests iPhone : [docs/PHASE1-TEST-IPHONE.md](docs/PHASE1-TEST-IPHONE.md)
