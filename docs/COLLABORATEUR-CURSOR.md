# Onboarding collaborateur — Cursor

Guide pour **Issa** (`issabrahim` / `issabrahim.ah@gmail.com`) afin de travailler sur Souk Tchad dans Cursor avec le même contexte projet que Hassan.

## 1. Cloner le dépôt

```bash
git clone https://github.com/Chogar/souk-tchad.git
cd souk-tchad
```

Accepter l'invitation GitHub si ce n'est pas déjà fait :  
https://github.com/Chogar/souk-tchad/invitations

## 2. Ouvrir dans Cursor

1. **File → Open Folder** → dossier `souk-tchad`
2. Cursor charge automatiquement :
   - `AGENTS.md` — instructions pour l'agent IA
   - `.cursor/rules/` — règles persistantes du projet

> **Important** : l'historique des conversations Cursor de Hassan **ne se synchronise pas** entre machines. Le contexte est recréé via les fichiers ci-dessus + `docs/HISTORIQUE-PROJET.md`. L'agent aura les mêmes informations projet, pas les anciens chats mot pour mot.

## 3. Environnement local

### Prérequis

- Node.js 20+, Flutter 3.41+, PostgreSQL (ou Docker)
- Xcode (pour iOS), Chrome (pour web)

### Installation

```bash
# Racine
npm run db:setup          # ou : docker compose up -d

# Backend
cp backend/.env.example backend/.env
cd backend && npm install && cd ..

# Mobile
cd mobile && flutter pub get && cd ..
```

### Fichiers secrets (demander à Hassan)

Hassan doit vous transmettre **en privé** (Signal, WhatsApp, pas GitHub) :

| Fichier | Contenu |
|---------|---------|
| `backend/.env` | DB, JWT, Google OAuth, SMTP, Gemini, Firebase |
| `mobile/.env` | `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` |

Puis :

```bash
bash scripts/write-dart-defines.sh
```

### Lancer le projet

```bash
# Terminal 1 — API
npm run backend:dev

# Terminal 2 — données démo (une fois)
npm run seed:dev

# Terminal 3 — mobile (exemple web)
API_BASE_URL_OVERRIDE=http://localhost:3000/api bash scripts/write-dart-defines.sh
cd mobile && flutter run -d chrome --dart-define-from-file=dart_defines.json
```

## 4. Travailler avec l'agent Cursor

Avant une tâche, vous pouvez dire à l'agent :

> « Lis `AGENTS.md` et `docs/HISTORIQUE-PROJET.md` pour le contexte Souk Tchad. »

Fichiers de référence :

| Fichier | Rôle |
|---------|------|
| `AGENTS.md` | Commandes, conventions, pièges |
| `docs/HISTORIQUE-PROJET.md` | Chronologie des features et bugs corrigés |
| `docs/PHASE1-TEST-IPHONE.md` | Checklist tests iPhone |
| `README.md` | Vue d'ensemble |

## 5. Git — workflow équipe

```bash
git pull origin master
# ... travail ...
git checkout -b feature/ma-fonctionnalite
git add ...
git commit -m "Description claire"
git push -u origin feature/ma-fonctionnalite
# Ouvrir une Pull Request sur GitHub
```

Ne jamais pousser `.env` ni `dart_defines.json`.

## 6. Contact

- Dépôt : https://github.com/Chogar/souk-tchad
- Lead : Hassan (Chogar)
