# Guide de publication — Souk Tchad sur Google Play Store

## Informations de l'application

- **Package Android** : `td.experience.souktchad`
- **Bundle iOS** : `td.experience.souktchad`
- **Version actuelle** : 1.0.0 (code 1)
- **Nom** : Souk Tchad

---

## 📋 Checklist avant publication

### 1. Configuration du keystore de signature ✅

Le keystore est essentiel pour signer votre application en mode release.

#### Générer le keystore (première fois uniquement)

```bash
cd mobile/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

**Questions lors de la génération :**
- Mot de passe du keystore : choisissez un mot de passe fort et SAUVEGARDEZ-LE
- Nom et prénom : Hassane Chogar (ou votre nom)
- Unité organisationnelle : Souk Tchad
- Organisation : Experience TD
- Ville : N'Djamena
- Province : Tchad
- Code pays : TD
- Mot de passe de la clé : peut être le même que le keystore

#### Configurer key.properties

```bash
cd mobile/android
cp key.properties.example key.properties
# Éditer key.properties avec vos vraies valeurs
```

Exemple de `key.properties` :
```properties
storeFile=upload-keystore.jks
storePassword=VotreMotDePasseSecurise123
keyAlias=upload
keyPassword=VotreMotDePasseSecurise123
```

⚠️ **IMPORTANT** : Ne committez JAMAIS `key.properties` ou le fichier `.jks` dans Git !

---

### 2. Configuration des services en production

#### A. Variables d'environnement backend (`backend/.env`)

Assurez-vous que votre backend est configuré avec de vrais services :

```env
# Base de données PostgreSQL de production
DATABASE_HOST=votre-serveur-prod.com
DATABASE_PORT=5432
DATABASE_USERNAME=souktchad_prod
DATABASE_PASSWORD=MotDePasseProdSecurise
DATABASE_NAME=souktchad_prod

# JWT
JWT_SECRET=UneLongueCleSecreteTresSécurisée
JWT_EXPIRATION=7d

# SMTP pour les OTP (obligatoire en production)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=votre-email@gmail.com
SMTP_PASS=votre-app-password
SMTP_FROM=noreply@souktchad.td

# Google OAuth
GOOGLE_CLIENT_ID=votre-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=votre-secret

# Gemini AI
GEMINI_API_KEY=votre-cle-gemini

# Firebase Admin (pour FCM)
FIREBASE_PROJECT_ID=votre-projet
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@votre-projet.iam.gserviceaccount.com

# URL API publique
API_BASE_URL=https://api.souktchad.td
```

#### B. Configuration mobile (`mobile/.env`)

```env
GOOGLE_CLIENT_ID=votre-android-client-id.apps.googleusercontent.com
GOOGLE_SERVER_CLIENT_ID=votre-web-client-id.apps.googleusercontent.com
```

#### C. Google AdMob - Remplacer l'ID de test

Actuellement, l'app utilise un ID de test AdMob. Pour la production :

1. Créez un compte AdMob sur https://admob.google.com
2. Créez une application "Souk Tchad"
3. Récupérez votre Application ID
4. Mettez à jour `AndroidManifest.xml` :

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-VOTRE_VRAI_ID~XXXXXXXXXX"/>
```

---

### 3. Builder l'application de release

#### A. Générer les dart_defines

```bash
cd /workspace
bash scripts/write-dart-defines.sh
```

Assurez-vous que `API_BASE_URL` pointe vers votre serveur de production dans le script.

#### B. Builder l'Android App Bundle (AAB) - Recommandé

```bash
cd mobile
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Le fichier sera généré dans :
```
mobile/build/app/outputs/bundle/release/app-release.aab
```

#### C. Ou builder un APK

```bash
cd mobile
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Le fichier sera généré dans :
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

**Note** : Google recommande l'AAB pour le Play Store.

---

### 4. Créer une application sur Google Play Console

1. Accédez à https://play.google.com/console
2. Créez un compte développeur (25 USD unique)
3. Cliquez sur "Créer une application"
4. Remplissez :
   - Nom : **Souk Tchad**
   - Langue par défaut : Français
   - Type : Application
   - Gratuite ou payante : Gratuite

---

### 5. Préparer les assets du Play Store

#### A. Icône de l'application
- Déjà configuré : `mobile/assets/icon/app_icon.png`
- Taille : 512x512 px (PNG)

#### B. Captures d'écran requises

**Téléphone (obligatoire)** :
- Minimum 2 captures, maximum 8
- Format : JPEG ou PNG 24 bits
- Taille recommandée : 1080 x 1920 px (ou 16:9)

**Tablette 7 pouces** (recommandé) :
- Minimum 2 captures
- Taille : 1024 x 768 px

**Tablette 10 pouces** (recommandé) :
- Minimum 2 captures
- Taille : 2048 x 1536 px

#### C. Bannière promotionnelle (optionnelle)
- Taille : 1024 x 500 px

#### D. Vidéo YouTube (optionnelle)
- Lien vers une vidéo de démo

---

### 6. Remplir les informations de l'application

#### A. Description courte (80 caractères max)
```
Marketplace tchadien - Achetez et vendez facilement
```

#### B. Description complète (4000 caractères max)

```
🇹🇩 Souk Tchad - Le marketplace tchadien de référence

Achetez et vendez facilement partout au Tchad !

🛍️ FONCTIONNALITÉS

• Publier des annonces gratuitement
• Recherche par catégorie (Véhicules, Immobilier, Électronique, Mode, etc.)
• Messagerie instantanée avec le vendeur
• Localisation GPS des annonces
• Partage d'annonces
• Favoris et alertes

📱 INTERFACE MODERNE

• Design intuitif et rapide
• Photos et vidéos HD
• Messagerie vocale
• Notifications push

🔒 SÉCURITÉ

• Authentification sécurisée (Google, Email)
• Signalement d'annonces suspectes
• Suppression de compte

✨ CATÉGORIES

Véhicules • Immobilier • Électronique • Mode • Maison • Loisirs • Services • Emploi

Rejoignez la communauté Souk Tchad dès aujourd'hui !
```

#### C. Catégorie
- **Catégorie principale** : Shopping
- **Balises** : marketplace, tchad, vente, achat

#### D. Coordonnées
- Email : support@souktchad.td (ou votre email)
- Téléphone : (optionnel)
- Site web : https://souktchad.td (quand disponible)

---

### 7. Politique de confidentialité (OBLIGATOIRE)

Vous DEVEZ fournir un lien vers une politique de confidentialité.

Options :
1. Créer une page sur votre site web
2. Héberger sur GitHub Pages
3. Utiliser un générateur en ligne

**Contenu minimum requis** :
- Quelles données sont collectées (nom, email, photos, localisation)
- Comment elles sont utilisées
- Comment les supprimer (fonction de suppression de compte)
- Politique concernant les mineurs
- Services tiers (Google Sign-In, Firebase, AdMob)

Exemple de générateur : https://www.freeprivacypolicy.com/

---

### 8. Classification du contenu

Répondez au questionnaire Google sur :
- Violence
- Contenu sexuel
- Langage grossier
- Drogues, alcool, tabac
- Contenu généré par les utilisateurs

**Pour Souk Tchad** :
- Contenu généré par les utilisateurs : **OUI**
- Modération : décrire votre système de signalement
- Âge minimum : 13+ ou 16+ selon votre politique

---

### 9. Tarification et distribution

- **Prix** : Gratuit
- **Pays** : Tchad (TD) + autres pays africains si souhaité
- **Disponibilité** : Tous les utilisateurs
- **Contient des publicités** : OUI (AdMob)
- **Achats intégrés** : NON (sauf si vous ajoutez des fonctionnalités premium)

---

### 10. Version de test interne (recommandé)

Avant la publication publique :

1. Créez une version de **test interne**
2. Ajoutez des testeurs (adresses Gmail)
3. Uploadez l'AAB
4. Testez pendant quelques jours
5. Corrigez les bugs éventuels

---

### 11. Uploader l'AAB sur Play Console

1. Allez dans **Production** > **Créer une version**
2. Cliquez sur **Créer une version** ou **Télécharger**
3. Uploadez `app-release.aab`
4. Remplissez les notes de version :

```
Version 1.0.0 - Lancement initial

✨ Fonctionnalités :
• Publication d'annonces avec photos et vidéos
• Recherche et filtrage par catégorie
• Messagerie instantanée
• Localisation GPS
• Favoris et partage
• Authentification Google et email
```

5. Enregistrez et cliquez sur **Vérifier la version**
6. Résolvez les avertissements éventuels
7. Cliquez sur **Démarrer le déploiement en production**

---

### 12. Révision Google (2-7 jours)

Google va examiner votre application :
- Conformité aux règles
- Fonctionnement correct
- Contenu approprié

Vous recevrez un email quand :
- ✅ L'app est approuvée et publiée
- ❌ L'app est refusée avec les raisons

---

## 🚀 Commandes récapitulatives

```bash
# 1. Générer le keystore (première fois)
cd mobile/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Configurer key.properties
cp key.properties.example key.properties
# Éditer avec vos valeurs

# 3. Générer dart_defines
cd /workspace
bash scripts/write-dart-defines.sh

# 4. Builder l'AAB
cd mobile
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=dart_defines.json

# 5. Vérifier l'AAB généré
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## 📱 Après publication

### Mises à jour futures

Pour publier une mise à jour :

1. Incrémenter la version dans `mobile/pubspec.yaml` :
```yaml
version: 1.0.1+2  # 1.0.1 = version name, 2 = version code
```

2. Rebuilder l'AAB
3. Uploader sur Play Console
4. Remplir les notes de version
5. Déployer

### Surveillance

- **Crash reports** : Google Play Console > Qualité > Rapports d'erreur
- **Avis utilisateurs** : Répondez aux avis
- **Statistiques** : Téléchargements, désinstallations, engagement

---

## ⚠️ Points d'attention

1. **Ne perdez JAMAIS le keystore** : Sauvegardez-le dans un cloud sécurisé
2. **SMTP en production** : Les OTP doivent être envoyés par email réel
3. **API_BASE_URL** : Doit pointer vers votre serveur de production
4. **AdMob ID** : Remplacez l'ID de test par votre vrai ID
5. **Firebase** : Configurez le projet Firebase pour la prod
6. **Politique de confidentialité** : Obligatoire pour la publication
7. **Test avant publication** : Utilisez la version de test interne

---

## 📞 Support

Pour toute question :
- Email : support@souktchad.td
- Documentation : `/workspace/docs/`

Bonne publication ! 🚀
