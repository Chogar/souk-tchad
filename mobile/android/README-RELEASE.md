# Configuration Release Android - Souk Tchad

## Package actuel

- **Package** : `td.experience.souktchad`
- **Version** : 1.0.0 (code 1)

## Configuration du Keystore

### 1. Générer le keystore (première fois uniquement)

```bash
# Depuis la racine du projet
bash scripts/generate-keystore.sh
```

Ou manuellement :

```bash
cd mobile/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

### 2. Créer key.properties

```bash
cp key.properties.example key.properties
```

Éditez `key.properties` avec vos valeurs :

```properties
storeFile=upload-keystore.jks
storePassword=VOTRE_MOT_DE_PASSE
keyAlias=upload
keyPassword=VOTRE_MOT_DE_PASSE
```

⚠️ **Ne committez JAMAIS `key.properties` ou `upload-keystore.jks` dans Git !**

### 3. Sauvegarder le keystore

Sauvegardez ces fichiers dans un endroit sécurisé :
- `upload-keystore.jks`
- Les mots de passe (storePassword, keyPassword)

Si vous perdez le keystore, vous ne pourrez plus mettre à jour votre application sur le Play Store.

## Builder l'application

### Méthode 1 : Script automatique (recommandé)

```bash
# AAB (Android App Bundle) - recommandé pour Play Store
bash scripts/build-release.sh appbundle

# APK
bash scripts/build-release.sh apk
```

### Méthode 2 : Commandes Flutter

```bash
# Générer dart_defines.json
bash scripts/write-dart-defines.sh

# Builder AAB
cd mobile
flutter build appbundle --release --dart-define-from-file=dart_defines.json

# Builder APK
flutter build apk --release --dart-define-from-file=dart_defines.json
```

## Fichiers générés

### AAB (recommandé)
```
mobile/build/app/outputs/bundle/release/app-release.aab
```

### APK
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Firebase Configuration

Pour mettre à jour Firebase avec le nouveau package :

1. Console Firebase : https://console.firebase.google.com
2. Projet → Paramètres → Vos applications
3. **Android** :
   - Ajouter une application Android
   - Package : `td.experience.souktchad`
   - Télécharger `google-services.json`
   - Copier vers `mobile/android/app/google-services.json`

4. **iOS** :
   - Ajouter une application iOS
   - Bundle ID : `td.experience.souktchad`
   - Télécharger `GoogleService-Info.plist`
   - Copier vers `mobile/ios/Runner/GoogleService-Info.plist`

## Google Sign-In Configuration

Après changement de package, mettez à jour :

1. **Google Cloud Console** : https://console.cloud.google.com
2. APIs & Services → Credentials
3. **OAuth 2.0 Client IDs** :
   - Android : nouveau SHA-1 avec nouveau package
   - Web : URL autorisées si nécessaire

### Obtenir le SHA-1 du keystore

```bash
cd mobile/android
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Notez le SHA-1 et ajoutez-le dans Firebase et Google Cloud Console.

## AdMob Configuration

⚠️ **ID de test actuel dans AndroidManifest.xml**

Pour la production, remplacez par votre vrai ID AdMob :

1. Créer un compte AdMob : https://admob.google.com
2. Ajouter l'application "Souk Tchad"
3. Obtenir l'Application ID
4. Mettre à jour `android/app/src/main/AndroidManifest.xml` :

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

## Vérifications avant publication

- [ ] Keystore configuré et sauvegardé
- [ ] `key.properties` créé avec les bons mots de passe
- [ ] Firebase configuré avec le nouveau package
- [ ] Google Sign-In mis à jour avec le nouveau SHA-1
- [ ] AdMob ID mis à jour (production)
- [ ] API_BASE_URL pointe vers la production dans `dart_defines.json`
- [ ] SMTP configuré pour l'envoi d'OTP
- [ ] Version incrémentée dans `pubspec.yaml`
- [ ] Build AAB réussi
- [ ] Test de l'APK sur un appareil physique

## Troubleshooting

### Erreur "keystore not found"

Vérifiez que `key.properties` existe et que le chemin `storeFile` est correct.

### Erreur de signature

Vérifiez que les mots de passe dans `key.properties` sont corrects.

### Google Sign-In ne fonctionne pas

1. Vérifiez le SHA-1 dans Firebase
2. Vérifiez les Client IDs dans `dart_defines.json`
3. Téléchargez à nouveau `google-services.json` depuis Firebase

### Build échoue

```bash
cd mobile
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

## Documentation complète

Voir `/workspace/docs/PUBLICATION-PLAY-STORE.md` pour le guide complet de publication.
