# 🚀 Guide de lancement - Souk Tchad

Guide pour lancer l'application Souk Tchad sur votre machine locale.

## ⚠️ Prérequis

### Installer les outils nécessaires

1. **Node.js** (v18+) : https://nodejs.org/
2. **Flutter** (v3.41+) : https://flutter.dev/docs/get-started/install
3. **PostgreSQL** (v14+) : https://www.postgresql.org/download/

### Vérifier les installations

```bash
node --version    # >= v18
npm --version     # >= 9
flutter --version # >= 3.41
psql --version    # >= 14
```

---

## 📋 Configuration initiale

### 1. Cloner le projet (si pas encore fait)

```bash
git clone https://github.com/Chogar/souk-tchad.git
cd souk-tchad
```

### 2. Récupérer la dernière branche

```bash
git checkout cursor/prepare-play-store-release-27d6
git pull origin cursor/prepare-play-store-release-27d6
```

---

## 🗄️ Configuration du Backend

### 1. Installer les dépendances

```bash
cd backend
npm install
```

### 2. Créer le fichier `.env`

```bash
cp .env.example .env
```

### 3. Éditer `backend/.env`

Ouvrez `backend/.env` et configurez au minimum :

```env
# Base de données PostgreSQL
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=votre_mot_de_passe
DATABASE_NAME=souktchad_dev

# JWT
JWT_SECRET=un_secret_de_developpement_local
JWT_EXPIRATION=7d

# Port API
PORT=3000

# Mode développement - affiche les OTP dans la console/app
NODE_ENV=development

# Google OAuth (optionnel en dev)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Gemini AI (optionnel en dev)
GEMINI_API_KEY=

# SMTP (optionnel en dev - OTP affiché dans console)
SMTP_HOST=
SMTP_PORT=
SMTP_SECURE=false
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@souktchad.local
```

### 4. Créer la base de données

```bash
# Méthode 1 : Script automatique
npm run db:setup

# Méthode 2 : Manuelle
psql -U postgres
CREATE DATABASE souktchad_dev;
\q
```

### 5. Lancer les migrations

```bash
npm run migration:run
```

### 6. (Optionnel) Ajouter des données de démo

```bash
# 100 annonces de démonstration
npm run seed:dev
```

### 7. Démarrer le backend

```bash
npm run backend:dev
```

Le backend sera accessible sur : **http://localhost:3000**

Vérifiez : http://localhost:3000/api (devrait retourner une réponse JSON)

---

## 📱 Configuration du Mobile

### 1. Installer les dépendances Flutter

```bash
cd mobile
flutter pub get
```

### 2. Créer le fichier `mobile/.env`

```bash
# Créer le fichier mobile/.env
cat > .env << 'EOF'
# Google Sign-In (optionnel en dev)
GOOGLE_CLIENT_ID=
GOOGLE_SERVER_CLIENT_ID=
EOF
```

### 3. Générer `dart_defines.json`

**Important** : Le nouveau package est `td.experience.souktchad`

```bash
# Depuis la racine du projet
cd ..
bash scripts/write-dart-defines.sh
```

Ce script va :
- Lire `mobile/.env`
- Générer `mobile/dart_defines.json` avec l'API_BASE_URL

### 4. Vérifier `dart_defines.json`

```bash
cat mobile/dart_defines.json
```

Devrait contenir :
```json
{
  "API_BASE_URL": "http://localhost:3000/api",
  "GOOGLE_CLIENT_ID": "",
  "GOOGLE_SERVER_CLIENT_ID": ""
}
```

---

## 🎯 Lancer l'application

### Sur Android (émulateur ou appareil)

#### 1. Démarrer un émulateur Android

```bash
# Lister les émulateurs disponibles
flutter emulator

# Lancer un émulateur
flutter emulator --launch <nom_emulateur>
```

#### 2. Lancer l'app

```bash
cd mobile
flutter run --dart-define-from-file=dart_defines.json
```

### Sur iOS (Mac uniquement)

#### 1. Installer les pods

```bash
cd ios
pod install
cd ..
```

#### 2. Démarrer un simulateur

```bash
open -a Simulator
```

#### 3. Lancer l'app

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### Sur Chrome (Web)

```bash
cd mobile
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

### Sur un appareil physique

#### Android

1. Activer le **Mode développeur** sur votre téléphone
2. Activer **Débogage USB**
3. Connecter le téléphone en USB
4. Autoriser le débogage sur le téléphone

```bash
# Vérifier que l'appareil est détecté
flutter devices

# Lancer l'app
cd mobile
flutter run --dart-define-from-file=dart_defines.json
```

#### iPhone (nécessite un Mac et un compte Apple Developer)

```bash
# Depuis la racine du projet
bash scripts/run-physical-iphone.sh
```

---

## 🔍 Vérifications

### Backend fonctionne ?

```bash
curl http://localhost:3000/api
```

Devrait retourner :
```json
{"message":"Souk Tchad API","version":"1.0.0"}
```

### L'app mobile se connecte au backend ?

1. Lancez l'app
2. Écran de splash devrait s'afficher
3. Écran d'accueil avec 100 annonces (si vous avez lancé `npm run seed:dev`)

### Tests de fonctionnalités de base

- ✅ Voir les annonces sur l'écran d'accueil
- ✅ Cliquer sur une annonce pour voir les détails
- ✅ Inscription (le code OTP s'affichera dans l'app si SMTP n'est pas configuré)
- ✅ Connexion
- ✅ Créer une annonce
- ✅ Messagerie

---

## 🐛 Résolution de problèmes

### Erreur : "Port 3000 already in use"

Le backend est déjà lancé. Soit :
- Utilisez ce backend
- Ou tuez le processus : `lsof -ti:3000 | xargs kill -9`

### Erreur : "Connection refused" dans l'app mobile

Le backend n'est pas lancé ou l'URL est incorrecte.

1. Vérifiez que le backend tourne : `curl http://localhost:3000/api`
2. Vérifiez `mobile/dart_defines.json` → `API_BASE_URL`

### Erreur : "No device found"

Aucun émulateur/appareil n'est connecté.

```bash
flutter devices  # Lister les appareils
flutter emulator # Lancer un émulateur
```

### Google Sign-In ne fonctionne pas

En développement, ce n'est pas obligatoire. Vous pouvez :
1. Utiliser l'inscription par email
2. Ou configurer les vrais Client IDs Google

### Les images ne s'affichent pas

Les annonces de démo utilisent picsum.photos. Vérifiez votre connexion internet.

### Erreur de migration de base de données

```bash
cd backend
npm run migration:revert
npm run migration:run
```

### L'app crash au démarrage

```bash
cd mobile
flutter clean
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

---

## 🎨 Développement

### Hot reload

Flutter supporte le hot reload :
1. Modifiez un fichier `.dart`
2. Tapez `r` dans le terminal où `flutter run` tourne
3. Ou `R` pour un full restart

### Logs backend

Les logs du backend s'affichent dans le terminal où vous avez lancé `npm run backend:dev`

### Logs mobile

Les logs Flutter s'affichent dans le terminal où vous avez lancé `flutter run`

### Changer l'URL de l'API

1. Éditez `scripts/write-dart-defines.sh` → ligne `API_BASE_URL`
2. Relancez : `bash scripts/write-dart-defines.sh`
3. Relancez l'app : `flutter run --dart-define-from-file=dart_defines.json`

---

## 📦 Commandes rapides

### Tout démarrer en une fois

```bash
# Terminal 1 : Backend
cd backend
npm install
npm run db:setup
npm run migration:run
npm run seed:dev
npm run backend:dev

# Terminal 2 : Mobile (dans un autre terminal)
cd mobile
flutter pub get
cd ..
bash scripts/write-dart-defines.sh
cd mobile
flutter run --dart-define-from-file=dart_defines.json
```

---

## 🚀 Nouveauté : Nouveau package

⚠️ **Le package a changé** : `td.experience.souktchad`

Si vous aviez une ancienne version installée :
1. Désinstallez l'ancienne app de votre téléphone
2. Réinstallez avec `flutter run`

---

## 📚 Documentation

- **Publication Play Store** : `docs/PUBLICATION-PLAY-STORE.md`
- **Agents Cursor** : `AGENTS.md`
- **Historique** : `docs/HISTORIQUE-PROJET.md`

---

## 💡 Astuces

### Lancer uniquement ce dont vous avez besoin

Vous n'avez pas besoin de tout :
- Pas besoin de PostgreSQL si vous utilisez juste l'UI (mais l'app crashera)
- Pas besoin de Google Sign-In (utilisez l'inscription email)
- Pas besoin d'AdMob en dev (ID de test déjà configuré)

### Mode release (pour tester les performances)

```bash
cd mobile
flutter run --release --dart-define-from-file=dart_defines.json
```

### Tester sur plusieurs appareils en même temps

```bash
# Terminal 1 : Android
flutter run -d android --dart-define-from-file=dart_defines.json

# Terminal 2 : Chrome
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

---

Bonne chance ! 🎉
