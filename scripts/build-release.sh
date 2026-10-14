#!/bin/bash

# Script de build release pour Souk Tchad
# Usage: bash scripts/build-release.sh [apk|appbundle]

set -e

cd "$(dirname "$0")/.."

BUILD_TYPE="${1:-appbundle}"

echo "🚀 Build release de Souk Tchad"
echo "==============================="
echo ""

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Erreur: Flutter n'est pas installé"
    exit 1
fi

# Vérifier que dart_defines.json existe
if [ ! -f "mobile/dart_defines.json" ]; then
    echo "⚠️  dart_defines.json n'existe pas. Génération..."
    bash scripts/write-dart-defines.sh
    if [ $? -ne 0 ]; then
        echo "❌ Erreur lors de la génération de dart_defines.json"
        exit 1
    fi
fi

# Vérifier que le keystore est configuré
if [ ! -f "mobile/android/key.properties" ]; then
    echo "⚠️  ATTENTION: key.properties n'existe pas"
    echo ""
    echo "Le build utilisera le signing DEBUG (non acceptable pour Play Store)."
    echo ""
    echo "Pour configurer le keystore :"
    echo "  1. bash scripts/generate-keystore.sh"
    echo "  2. cp mobile/android/key.properties.example mobile/android/key.properties"
    echo "  3. Éditer key.properties avec vos valeurs"
    echo ""
    read -p "Continuer quand même avec le signing debug ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Build annulé"
        exit 1
    fi
fi

cd mobile

echo "📦 Nettoyage..."
flutter clean

echo "📥 Récupération des dépendances..."
flutter pub get

if [ "$BUILD_TYPE" = "appbundle" ]; then
    echo "🏗️  Build de l'Android App Bundle (AAB)..."
    flutter build appbundle --release --dart-define-from-file=dart_defines.json
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Build réussi !"
        echo ""
        echo "📦 Fichier généré :"
        ls -lh build/app/outputs/bundle/release/app-release.aab
        echo ""
        echo "📍 Chemin complet :"
        echo "   $(pwd)/build/app/outputs/bundle/release/app-release.aab"
        echo ""
        echo "🚀 Prochaine étape : Upload sur Google Play Console"
    else
        echo ""
        echo "❌ Erreur lors du build"
        exit 1
    fi
    
elif [ "$BUILD_TYPE" = "apk" ]; then
    echo "🏗️  Build de l'APK..."
    flutter build apk --release --dart-define-from-file=dart_defines.json
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Build réussi !"
        echo ""
        echo "📦 Fichier généré :"
        ls -lh build/app/outputs/flutter-apk/app-release.apk
        echo ""
        echo "📍 Chemin complet :"
        echo "   $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo "⚠️  Note : Google Play recommande l'AAB plutôt que l'APK"
        echo "   Pour builder un AAB : bash scripts/build-release.sh appbundle"
    else
        echo ""
        echo "❌ Erreur lors du build"
        exit 1
    fi
else
    echo "❌ Type de build invalide: $BUILD_TYPE"
    echo "Usage: bash scripts/build-release.sh [apk|appbundle]"
    exit 1
fi
