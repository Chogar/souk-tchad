# Historique projet Souk Tchad

Chronologie des décisions et travaux (juin 2026).  
Ce document remplace l'historique des chats Cursor pour les collaborateurs.

---

## Octobre 2026 — Préparation publication Play Store

### Changement de package (14 octobre 2026)

**Package modifié** : `com.hassanechogar.souktchad` → `td.experience.souktchad`

**Raison** : Préparation pour la publication sur Google Play Store avec un identifiant professionnel représentant "Experience TD".

**Fichiers modifiés** :
- Android : `build.gradle.kts`, `MainActivity.kt`, `google-services.json.example`
- iOS : `project.pbxproj`, `GoogleService-Info.plist.example`

**Documentation créée** :
- `docs/PUBLICATION-PLAY-STORE.md` — Guide complet de publication
- `mobile/android/README-RELEASE.md` — Configuration release Android
- `mobile/android/key.properties.example` — Template keystore
- `CHANGEMENT-PACKAGE.md` — Récapitulatif du changement

**Scripts créés** :
- `scripts/generate-keystore.sh` — Génération automatique du keystore
- `scripts/build-release.sh` — Build automatique AAB/APK

**Actions requises avant publication** :
1. Reconfigurer Firebase avec le nouveau package
2. Mettre à jour Google OAuth Client IDs
3. Générer le keystore de production
4. Configurer les services backend en production (SMTP, etc.)
5. Remplacer l'ID AdMob de test par un ID de production

**Impact** : Nouvelle application sur le Play Store (pas de mise à jour d'une app existante).

---

## Architecture

- **Monorepo** : `backend/` NestJS + PostgreSQL, `mobile/` Flutter (Android, iOS, Web)
- **Hébergement cible** : VPS LWS (pas encore déployé)
- **Langues app** : FR, AR, EN

---

## Fonctionnalités livrées

### Auth & compte

- Connexion e-mail / mot de passe
- Google Sign-In (IDs via `write-dart-defines.sh` → `dart_defines.json`)
- Inscription en 3 écrans :
  1. `RegisterScreen` — e-mail + « Choisir mon Gmail »
  2. `RegisterOtpScreen` — code OTP 6 chiffres
  3. `RegisterProfileScreen` — nom, téléphone, mot de passe
- OTP : envoyé par SMTP en prod ; en dev le code s'affiche dans l'app si SMTP non configuré
- Suppression compte : `DELETE /api/users/me` + bouton « Supprimer mon compte » dans le profil

### Catalogue

- 8 catégories
- **100 annonces démo** (`demo-listings.catalog.ts`, images picsum.photos)
- Scripts : `npm run seed:dev`, `npm run seed:dev:reset`

### Mobile / Web

- 15 écrans (splash, auth×4, home, favoris, messages, profil, détail, créer/modifier annonce, mes annonces, chat, abonnements)
- Chat temps réel Socket.io
- Favoris, abonnements (4 plans), IA Gemini
- Cache offline SQLite (mobile) ; cache mémoire sur **web**
- Grille accueil : **3 colonnes** mobile, **6 colonnes** web (`home_screen.dart`)
- Aperçu HTML : `docs/apercu/index.html`

---

## Bugs corrigés

| Bug | Solution |
|-----|----------|
| Catalogue qui se rafraîchissait en boucle | Retrait `bumpCatalogVersion` dans sync arrière-plan listings/categories |
| Profil non persisté | `setUser` async + garde-fou `refreshUser` 90s |
| Images démo Unsplash instables | picsum.photos dans le seed |
| Google Sign-In sans effet | `write-dart-defines.sh` injecte OAuth à la compilation |
| Web crash au démarrage (SQLite) | `CacheService` avec branche `kIsWeb` mémoire |

---

## Scripts importants

| Script | Usage |
|--------|-------|
| `scripts/write-dart-defines.sh` | Génère `mobile/dart_defines.json` |
| `scripts/run-physical-iphone.sh` | Run iPhone physique |
| `scripts/install-sans-cable.sh` | Install sans câble |
| `scripts/phase1-test-api.sh` | Tests API automatisés |
| `scripts/check-serveur.sh` | Vérifie backend + réseau |

---

## Configuration actuelle (dev)

- Backend port **3000** — `npm run backend:dev` depuis la racine
- `backend/.env` : Google OAuth OK, SMTP souvent commenté en dev
- `mobile/.env` : `GOOGLE_CLIENT_ID` + `GOOGLE_SERVER_CLIENT_ID`
- iPhone physique : IP Mac Wi‑Fi dans dart_defines (pas localhost)

---

## Roadmap restante

1. Tests iPhone complets (checklist `PHASE1-TEST-IPHONE.md`)
2. SMTP Gmail production (codes OTP par e-mail)
3. Firebase FCM + fichiers iOS/Android
4. Builds release stores
5. Déploiement VPS LWS + SSL + domaine
6. Paiements (Google Play / App Store)

---

## Dépôt GitHub

- URL : https://github.com/Chogar/souk-tchad (privé)
- Branche principale : `master`
- Collaborateur invité : `issabrahim`
