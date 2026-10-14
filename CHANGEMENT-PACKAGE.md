# Changement de Package - Souk Tchad

**Date** : 14 octobre 2026

## Changements effectués

### Ancien package
- `com.hassanechogar.souktchad`

### Nouveau package
- `td.experience.souktchad`

## Fichiers modifiés

### Android

1. **`mobile/android/app/build.gradle.kts`**
   - `namespace` : `td.experience.souktchad`
   - `applicationId` : `td.experience.souktchad`

2. **`mobile/android/app/src/main/kotlin/td/experience/souktchad/MainActivity.kt`**
   - Package Kotlin mis à jour
   - Fichier déplacé vers le nouveau répertoire

3. **`mobile/android/app/google-services.json.example`**
   - `package_name` : `td.experience.souktchad`

### iOS

4. **`mobile/ios/Runner.xcodeproj/project.pbxproj`**
   - `PRODUCT_BUNDLE_IDENTIFIER` : `td.experience.souktchad`

5. **`mobile/ios/Runner/GoogleService-Info.plist.example`**
   - `BUNDLE_ID` : `td.experience.souktchad`

## Nouveaux fichiers créés

### Documentation

1. **`docs/PUBLICATION-PLAY-STORE.md`**
   - Guide complet de publication sur Google Play Store
   - Checklist avant publication
   - Configuration des services en production
   - Instructions détaillées

2. **`mobile/android/README-RELEASE.md`**
   - Configuration du keystore
   - Instructions de build
   - Troubleshooting

3. **`mobile/android/key.properties.example`**
   - Template pour la configuration du keystore
   - Instructions de génération

### Scripts

4. **`scripts/generate-keystore.sh`**
   - Script automatique de génération du keystore
   - Vérifications et validations
   - Instructions interactives

5. **`scripts/build-release.sh`**
   - Script de build automatique (AAB ou APK)
   - Vérifications préalables
   - Support AAB et APK

## Actions requises après ce changement

### 1. Firebase Console

⚠️ **IMPORTANT** : Reconfigurer Firebase avec le nouveau package

#### Android
1. Console Firebase → Paramètres → Ajouter une application Android
2. Package : `td.experience.souktchad`
3. Télécharger `google-services.json`
4. Copier vers `mobile/android/app/google-services.json`

#### iOS
1. Console Firebase → Paramètres → Ajouter une application iOS
2. Bundle ID : `td.experience.souktchad`
3. Télécharger `GoogleService-Info.plist`
4. Copier vers `mobile/ios/Runner/GoogleService-Info.plist`

### 2. Google Cloud Console (OAuth)

⚠️ **IMPORTANT** : Mettre à jour les OAuth Client IDs

1. https://console.cloud.google.com
2. APIs & Services → Credentials
3. **Android Client ID** :
   - Nouveau package : `td.experience.souktchad`
   - Nouveau SHA-1 du keystore de production
4. **Mettre à jour dans** :
   - `backend/.env` → `GOOGLE_CLIENT_ID`
   - `mobile/.env` → `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`

### 3. Générer le keystore de production

```bash
bash scripts/generate-keystore.sh
```

Puis créer `mobile/android/key.properties` :

```bash
cp mobile/android/key.properties.example mobile/android/key.properties
# Éditer avec vos valeurs
```

### 4. Obtenir le SHA-1 du nouveau keystore

```bash
cd mobile/android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Ajouter ce SHA-1 dans :
- Firebase Console (Paramètres → Vos applications → Android → SHA-1)
- Google Cloud Console (Credentials → Android Client ID)

### 5. Mettre à jour AdMob (production)

1. Créer un compte AdMob : https://admob.google.com
2. Ajouter l'application "Souk Tchad"
3. Récupérer l'Application ID
4. Mettre à jour `mobile/android/app/src/main/AndroidManifest.xml` :

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-VOTRE_ID~XXXXXXXXXX"/>
```

### 6. Configurer les services backend en production

Éditer `backend/.env` avec les vraies valeurs :

- ✅ Base de données PostgreSQL de production
- ✅ SMTP pour l'envoi d'OTP (obligatoire)
- ✅ JWT secret sécurisé
- ✅ Google OAuth avec nouveau Client ID
- ✅ Gemini API Key
- ✅ Firebase Admin SDK
- ✅ URL API publique

### 7. Mettre à jour dart_defines.json

```bash
# Assurez-vous que API_BASE_URL pointe vers la production
bash scripts/write-dart-defines.sh
```

### 8. Builder l'application

```bash
bash scripts/build-release.sh appbundle
```

Le fichier AAB sera généré dans :
```
mobile/build/app/outputs/bundle/release/app-release.aab
```

## Google Play Console

### Première publication

1. Créer un compte développeur : https://play.google.com/console (25 USD)
2. Créer une application "Souk Tchad"
3. Package : `td.experience.souktchad`
4. Suivre le guide : `docs/PUBLICATION-PLAY-STORE.md`

### Points importants

- ✅ Politique de confidentialité (obligatoire)
- ✅ Captures d'écran (minimum 2)
- ✅ Description courte et complète
- ✅ Icône 512x512 px
- ✅ Catégorie : Shopping
- ✅ Classification du contenu
- ✅ Version de test interne (recommandé)

## Compatibilité

### Utilisateurs existants

⚠️ **ATTENTION** : Le changement de package crée techniquement une nouvelle application.

Si des utilisateurs ont déjà installé l'app avec l'ancien package :
- Ils ne recevront **PAS** de mise à jour automatique
- Ils devront désinstaller l'ancienne app et installer la nouvelle
- Leurs données locales seront perdues (cache SQLite, préférences)

**Recommandation** : Comme l'app est en phase de développement et pas encore publiée sur le Play Store, c'est le bon moment pour changer le package.

### Impact sur les services

- ✅ **Backend API** : Aucun impact (l'API ne dépend pas du package)
- ⚠️ **Firebase** : Reconfiguration nécessaire (nouveau google-services.json)
- ⚠️ **Google Sign-In** : Nouveaux Client IDs nécessaires
- ⚠️ **Push Notifications** : Nouveau token FCM (automatique)
- ⚠️ **AdMob** : Nouvel Application ID nécessaire

## Tests recommandés avant publication

1. ✅ Installation sur appareil physique Android
2. ✅ Google Sign-In fonctionne
3. ✅ Inscription OTP fonctionne (email réel envoyé)
4. ✅ Push notifications fonctionnent
5. ✅ Upload d'images fonctionne
6. ✅ Messagerie en temps réel fonctionne
7. ✅ AdMob affiche des annonces
8. ✅ Suppression de compte fonctionne

## Rollback (si nécessaire)

Pour revenir à l'ancien package :

```bash
git checkout master
# ou
git revert <commit-hash>
```

**Note** : Déconseillé après publication sur le Play Store.

## Commandes rapides

```bash
# Générer keystore
bash scripts/generate-keystore.sh

# Configurer key.properties
cp mobile/android/key.properties.example mobile/android/key.properties
# Éditer avec vos valeurs

# Générer dart_defines
bash scripts/write-dart-defines.sh

# Builder AAB
bash scripts/build-release.sh appbundle

# Obtenir SHA-1
cd mobile/android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

## Documentation

- 📖 [Guide complet de publication](docs/PUBLICATION-PLAY-STORE.md)
- 📱 [Configuration release Android](mobile/android/README-RELEASE.md)
- 🔐 [Exemple keystore](mobile/android/key.properties.example)

## Support

Pour toute question sur ces changements :
- Documentation complète : `/workspace/docs/`
- Scripts disponibles : `/workspace/scripts/`

---

**Prochaine étape** : Suivre `docs/PUBLICATION-PLAY-STORE.md` pour publier l'application.
