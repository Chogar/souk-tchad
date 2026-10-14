#!/bin/bash

# Script de génération du keystore pour Souk Tchad
# Usage: bash scripts/generate-keystore.sh

set -e

cd "$(dirname "$0")/.."

echo "🔐 Génération du keystore pour Souk Tchad"
echo "=========================================="
echo ""

# Vérifier si keytool est disponible
if ! command -v keytool &> /dev/null; then
    echo "❌ Erreur: keytool n'est pas installé"
    echo "keytool fait partie du JDK. Installez Java Development Kit."
    exit 1
fi

# Vérifier si le keystore existe déjà
if [ -f "mobile/android/upload-keystore.jks" ]; then
    echo "⚠️  Le keystore existe déjà : mobile/android/upload-keystore.jks"
    read -p "Voulez-vous le remplacer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Génération annulée"
        exit 1
    fi
    rm mobile/android/upload-keystore.jks
fi

echo "📝 Vous allez devoir répondre à quelques questions..."
echo ""
echo "Informations suggérées :"
echo "  - Nom et prénom : Hassane Chogar"
echo "  - Unité organisationnelle : Souk Tchad"
echo "  - Organisation : Experience TD"
echo "  - Ville : N'Djamena"
echo "  - Province : Tchad"
echo "  - Code pays (2 lettres) : TD"
echo ""
echo "⚠️  IMPORTANT : Notez bien les mots de passe que vous allez choisir !"
echo "   Si vous les perdez, vous ne pourrez plus mettre à jour votre app."
echo ""

# Générer le keystore
cd mobile/android

keytool -genkey -v \
    -keystore upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore généré avec succès : mobile/android/upload-keystore.jks"
    echo ""
    echo "📋 Prochaines étapes :"
    echo ""
    echo "1. Créez le fichier key.properties :"
    echo "   cp mobile/android/key.properties.example mobile/android/key.properties"
    echo ""
    echo "2. Éditez key.properties avec vos mots de passe :"
    echo "   storeFile=upload-keystore.jks"
    echo "   storePassword=VOTRE_MOT_DE_PASSE"
    echo "   keyAlias=upload"
    echo "   keyPassword=VOTRE_MOT_DE_PASSE"
    echo ""
    echo "3. SAUVEGARDEZ le keystore et les mots de passe en lieu sûr !"
    echo ""
    echo "4. Buildez l'application :"
    echo "   cd mobile"
    echo "   flutter build appbundle --release --dart-define-from-file=dart_defines.json"
    echo ""
else
    echo ""
    echo "❌ Erreur lors de la génération du keystore"
    exit 1
fi
