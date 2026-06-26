#!/usr/bin/env bash
# Installe ou met à jour l'app sur iPhone via Wi‑Fi (sans câble USB).
# Prérequis : iPhone déjà appairé en sans fil dans Xcode (Window → Devices).
exec "$(cd "$(dirname "$0")/.." && pwd)/scripts/install-sans-cable.sh" "$@"
