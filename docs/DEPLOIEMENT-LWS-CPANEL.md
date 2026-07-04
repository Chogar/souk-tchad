# Déploiement backend Souk Tchad sur LWS cPanel L2

Guide pas à pas pour héberger l'API NestJS (PostgreSQL + Node.js) sur un hébergement **cPanel L2 LWS**.

> **Prérequis LWS** : Node.js activé, PostgreSQL (Cloud cPanel), accès SSH, certificat SSL.
> Tutoriel LWS Node.js : https://tutoriels.lws.fr/divers/nodejs-cpanel

---

## Vue d'ensemble

| Composant | Valeur |
|-----------|--------|
| Stack | NestJS 11 + PostgreSQL + Socket.io |
| URL API (prod) | `https://apisouk.experiencetech-td.com` |
| Point d'entrée | `dist/main.js` |
| Dossier uploads | `backend/uploads/` (writable) |

### Limitations cPanel mutualisé

- **Chat temps réel (WebSocket)** : peut nécessiter un sous-domaine dédié ou un VPS si les connexions Socket.io échouent derrière le proxy cPanel. L'API REST fonctionne normalement.
- **Ne pas uploader `node_modules`** : installer les dépendances sur le serveur.
- **Premier déploiement** : lancer `npm run db:init-prod` une seule fois pour créer les tables.

---

## Phase 1 — Préparer le domaine (cPanel)

### 1.1 Sous-domaine API (déjà défini)

**URL cible :** `https://apisouk.experiencetech-td.com`

1. Connectez-vous à **cPanel LWS** (`https://cpanel.experiencetech-td.com:2083` ou le lien fourni par LWS).
2. Vérifiez que le sous-domaine **`apisouk`** existe (Domaines → Sous-domaines).
3. Activez le **certificat SSL** (Let's Encrypt / AutoSSL) pour `apisouk.experiencetech-td.com`.

### 1.2 Créer la base PostgreSQL

1. cPanel → **PostgreSQL Databases** (ou Bases PostgreSQL).
2. **Créer une base** : ex. `user_souktchad`
3. **Créer un utilisateur** : ex. `user_soukapi` + mot de passe fort
4. **Associer** l'utilisateur à la base avec **ALL PRIVILEGES**
5. Notez :
   - `DATABASE_HOST` → en général `localhost`
   - `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`

### 1.3 Créer la boîte mail SMTP (optionnel mais recommandé)

1. cPanel → **Comptes de messagerie**
2. Créez `noreply@experiencetech-td.com` (recommandé)
3. Utilisez ces identifiants pour `SMTP_*` dans `.env`

---

## Phase 2 — Uploader le code

### 2.1 Structure sur le serveur

```
/home/VOTRE_USER/
└── souk-tchad/
    └── backend/          ← dossier de l'application Node.js
        ├── src/
        ├── scripts/
        ├── package.json
        ├── package-lock.json
        ├── tsconfig.json
        ├── nest-cli.json
        └── .env          ← à créer sur le serveur (jamais dans Git)
```

### 2.2 Méthode A — Git (recommandée)

Via **Terminal SSH** cPanel :

```bash
cd ~
git clone https://github.com/Chogar/souk-tchad.git
cd souk-tchad/backend
cp .env.production.example .env
nano .env   # ou éditeur cPanel File Manager
```

### 2.2 Méthode B — File Manager / FTP

1. Compressez le dossier `backend/` **sans** `node_modules`, `dist`, `.env`
2. Uploadez dans `/home/VOTRE_USER/souk-tchad/backend/`
3. Décompressez sur le serveur

---

## Phase 3 — Configurer `.env` production

Copiez `backend/.env.production.example` vers `backend/.env` et remplissez :

```env
NODE_ENV=production
PORT=3000

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=c2748744c_usouktchad
DATABASE_PASSWORD=********
DATABASE_NAME=c2748744c_souktchad

JWT_SECRET=une-cle-tres-longue-aleatoire-minimum-64-caracteres

APP_URL=https://apisouk.experiencetech-td.com

GOOGLE_CLIENT_ID=...
SMTP_HOST=mail.experiencetech-td.com
SMTP_USER=noreply@experiencetech-td.com
SMTP_PASS=...
SMTP_FROM=Souk Tchad <noreply@experiencetech-td.com>

GEMINI_API_KEY=...
# Firebase si notifications push activées
```

**Générer JWT_SECRET** (en local ou SSH) :

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

---

## Phase 4 — Installer et builder (SSH)

```bash
cd ~/souk-tchad/backend

# Si erreur "permission denied" npm :
# cp .npmrc.example ~/.npmrc  (adapter USERNAME)

# Installer dépendances + compiler TypeScript
npm ci
npm run build

# Créer les dossiers uploads (images, chat, etc.)
mkdir -p uploads/listings/videos uploads/avatars uploads/voice uploads/chat/images uploads/chat/documents
chmod -R 755 uploads

# UNE SEULE FOIS : créer les tables + catégories
npm run db:init-prod
```

Vérification locale sur le serveur :

```bash
node dist/main.js
# Ctrl+C après test, ou laisser cPanel gérer le processus
curl http://127.0.0.1:3000/api/categories
```

---

## Phase 5 — Configurer l'application Node.js (cPanel)

1. cPanel → **Setup Node.js App** (ou **Application Node.js**)
2. Cliquez **Create Application**
3. Renseignez :

| Champ | Valeur |
|-------|--------|
| Node.js version | **20** ou **24** LTS |
| Application mode | **Production** |
| Application root | `/home/VOTRE_USER/souk-tchad/backend` |
| Application URL | `apisouk.experiencetech-td.com` |
| Application startup file | `dist/main.js` |

4. Cliquez **Add Variable** pour chaque variable de `.env` **OU** laissez le fichier `.env` (NestJS ConfigModule le charge automatiquement depuis la racine backend).

5. **Run NPM Install** (bouton cPanel) si disponible, sinon déjà fait en SSH.

6. Cliquez **Restart** / **Start**.

> cPanel (Passenger) injecte souvent `PORT` automatiquement. Si l'app ne démarre pas, ajoutez la variable `PORT` affichée dans l'interface Node.js.

---

## Phase 6 — Vérifier le déploiement

### 6.1 Tests HTTP

```bash
curl https://apisouk.experiencetech-td.com/
curl https://apisouk.experiencetech-td.com/api/categories
```

Réponse attendue : JSON avec les 9 catégories.

### 6.2 Mettre à jour l'app mobile

Rebuild Flutter avec la nouvelle URL :

```bash
flutter run --dart-define=API_BASE_URL=https://apisouk.experiencetech-td.com/api
```

Ou modifiez `mobile/.env` / CI pour la production.

### 6.3 Google OAuth

Dans [Google Cloud Console](https://console.cloud.google.com/) :

- Ajoutez `https://apisouk.experiencetech-td.com` aux origines autorisées
- Mettez à jour `GOOGLE_CLIENT_ID` dans `.env`

---

## Phase 7 — Mises à jour ultérieures

```bash
cd ~/souk-tchad
git pull
cd backend
npm ci
npm run build
# cPanel → Setup Node.js App → Restart
```

---

## Dépannage

| Problème | Solution |
|----------|----------|
| `EACCES` npm | Configurer `~/.npmrc` (voir `.npmrc.example`) |
| Erreur PostgreSQL | Vérifier user/base/privilèges cPanel |
| 502 Bad Gateway | Restart app Node.js ; vérifier `dist/main.js` existe |
| Tables manquantes | Relancer `npm run db:init-prod` (une fois) |
| Images 404 | Vérifier permissions `uploads/` (755) |
| Chat ne connecte pas | WebSocket limité sur mutualisé → VPS LWS si critique |
| CORS | Déjà `origin: true` dans `main.ts` |

**Logs** : cPanel → **Errors** / **Setup Node.js App → Open log** / `~/souk-tchad/backend` stderr Passenger.

---

## Checklist finale

- [ ] Sous-domaine `apisouk.experiencetech-td.com` + SSL actif
- [ ] Base PostgreSQL créée et `.env` rempli
- [ ] `npm ci && npm run build` OK
- [ ] `npm run db:init-prod` exécuté (1×)
- [ ] App Node.js cPanel démarrée
- [ ] `GET /api/categories` répond en HTTPS
- [ ] App mobile pointée vers l'URL prod
- [ ] SMTP + Google OAuth configurés

---

## Support LWS

En cas de blocage Node.js ou PostgreSQL : ticket support LWS en mentionnant **cPanel L2**, **Node.js 20+**, **PostgreSQL**, application **NestJS**.
