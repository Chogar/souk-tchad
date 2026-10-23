#!/bin/bash

# Script de démarrage rapide pour Souk Tchad (développement)
# Usage: bash scripts/start-dev.sh [backend|mobile|all]

set -e

cd "$(dirname "$0")/.."

MODE="${1:-all}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Démarrage de Souk Tchad (mode: $MODE)${NC}"
echo "=========================================="
echo ""

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour afficher une erreur et sortir
error_exit() {
    echo -e "${RED}❌ Erreur: $1${NC}" >&2
    exit 1
}

# Vérifications des prérequis
check_prerequisites() {
    if [ "$MODE" = "backend" ] || [ "$MODE" = "all" ]; then
        if ! command_exists node; then
            error_exit "Node.js n'est pas installé. Installez-le depuis https://nodejs.org/"
        fi
        
        if ! command_exists psql; then
            echo -e "${YELLOW}⚠️  PostgreSQL n'est pas installé ou pas dans le PATH${NC}"
            echo "   Assurez-vous que PostgreSQL est installé et que la base de données est créée."
        fi
    fi
    
    if [ "$MODE" = "mobile" ] || [ "$MODE" = "all" ]; then
        if ! command_exists flutter; then
            error_exit "Flutter n'est pas installé. Installez-le depuis https://flutter.dev/"
        fi
    fi
}

# Démarrer le backend
start_backend() {
    echo -e "${BLUE}📦 Configuration du backend...${NC}"
    
    cd backend
    
    # Vérifier .env
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠️  backend/.env n'existe pas${NC}"
        read -p "Voulez-vous le créer depuis .env.example ? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp .env.example .env
            echo -e "${GREEN}✅ .env créé. ÉDITEZ-LE avant de continuer !${NC}"
            echo "   Appuyez sur Entrée pour continuer..."
            read
        else
            error_exit "backend/.env est requis"
        fi
    fi
    
    # Installer les dépendances si nécessaire
    if [ ! -d "node_modules" ]; then
        echo -e "${BLUE}📥 Installation des dépendances backend...${NC}"
        npm install
    fi
    
    # Vérifier si le port 3000 est occupé
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Le port 3000 est déjà utilisé${NC}"
        read -p "Voulez-vous tuer le processus existant ? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            lsof -ti:3000 | xargs kill -9 2>/dev/null || true
            echo -e "${GREEN}✅ Processus tué${NC}"
        else
            echo -e "${YELLOW}⚠️  Le backend ne sera pas démarré${NC}"
            cd ..
            return
        fi
    fi
    
    echo -e "${GREEN}🚀 Démarrage du backend sur http://localhost:3000${NC}"
    echo ""
    npm run backend:dev
}

# Démarrer le mobile
start_mobile() {
    echo -e "${BLUE}📱 Configuration du mobile...${NC}"
    
    # Vérifier mobile/.env
    if [ ! -f "mobile/.env" ]; then
        echo -e "${YELLOW}⚠️  mobile/.env n'existe pas${NC}"
        if [ -f "mobile/.env.example" ]; then
            cp mobile/.env.example mobile/.env
            echo -e "${GREEN}✅ mobile/.env créé depuis .env.example${NC}"
        else
            cat > mobile/.env << 'EOF'
GOOGLE_CLIENT_ID=
GOOGLE_SERVER_CLIENT_ID=
EOF
            echo -e "${GREEN}✅ mobile/.env créé (vide)${NC}"
        fi
    fi
    
    # Générer dart_defines.json
    if [ ! -f "mobile/dart_defines.json" ]; then
        echo -e "${BLUE}📝 Génération de dart_defines.json...${NC}"
        bash scripts/write-dart-defines.sh
    fi
    
    cd mobile
    
    # Installer les dépendances si nécessaire
    if [ ! -d ".dart_tool" ]; then
        echo -e "${BLUE}📥 Installation des dépendances Flutter...${NC}"
        flutter pub get
    fi
    
    # Vérifier les appareils disponibles
    echo -e "${BLUE}🔍 Recherche d'appareils disponibles...${NC}"
    DEVICES=$(flutter devices 2>&1)
    
    if echo "$DEVICES" | grep -q "No devices found"; then
        echo -e "${YELLOW}⚠️  Aucun appareil trouvé${NC}"
        echo ""
        echo "Options :"
        echo "  1. Démarrer un émulateur Android : flutter emulator --launch <nom>"
        echo "  2. Lancer Chrome : flutter run -d chrome"
        echo "  3. Connecter un appareil physique en USB"
        echo ""
        read -p "Voulez-vous lancer sur Chrome ? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${GREEN}🚀 Démarrage sur Chrome...${NC}"
            flutter run -d chrome --dart-define-from-file=dart_defines.json
        else
            echo -e "${YELLOW}⚠️  Aucun appareil sélectionné${NC}"
            cd ..
            return
        fi
    else
        echo -e "${GREEN}✅ Appareils trouvés :${NC}"
        echo "$DEVICES"
        echo ""
        echo -e "${GREEN}🚀 Démarrage de l'application...${NC}"
        flutter run --dart-define-from-file=dart_defines.json
    fi
}

# Vérifier les prérequis
check_prerequisites

# Démarrer selon le mode
case $MODE in
    backend)
        start_backend
        ;;
    mobile)
        # Vérifier que le backend tourne
        if ! curl -s http://localhost:3000/api >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Le backend ne semble pas tourner sur http://localhost:3000${NC}"
            echo "   L'application mobile risque de ne pas fonctionner correctement."
            echo ""
            read -p "Continuer quand même ? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}💡 Lancez d'abord le backend :${NC}"
                echo "   bash scripts/start-dev.sh backend"
                exit 1
            fi
        fi
        start_mobile
        ;;
    all)
        echo -e "${YELLOW}⚠️  Mode 'all' : Vous devez lancer backend et mobile dans 2 terminaux séparés${NC}"
        echo ""
        echo "Terminal 1 :"
        echo "  bash scripts/start-dev.sh backend"
        echo ""
        echo "Terminal 2 :"
        echo "  bash scripts/start-dev.sh mobile"
        echo ""
        exit 0
        ;;
    *)
        error_exit "Mode invalide: $MODE. Utilisez: backend, mobile, ou all"
        ;;
esac
