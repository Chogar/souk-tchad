# Phase 1 — Tests iPhone Souk Tchad

Date : juin 2026  
API locale : `http://192.168.2.133:3000/api` (IP Wi‑Fi du Mac — peut changer)

## Annonces de test en base

**27 annonces** dont **18 préfixées `[Démo]`** — toutes les 8 catégories couvertes.

| Catégorie | Exemple démo |
|-----------|----------------|
| Automobiles | `[Démo] Toyota Hilux 2019` |
| Immobilier | `[Démo] Appartement F3 Moursal` |
| Électronique | `[Démo] iPhone 14 Pro 256 Go` |
| Emplois | `[Démo] Offre chauffeur-livreur` |
| Services | `[Démo] Réparation climatisation` |
| Meubles | `[Démo] Canapé 3 places` |
| Mode | `[Démo] Boubou brodé traditionnel` |
| Animaux | `[Démo] Chèvres locales (lot de 5)` |

Les annonces démo utilisent des photos en ligne (picsum.photos). **Wi‑Fi requis** pour ces images.

### Recharger les annonces démo

```bash
cd backend && npm run seed:dev
```

---

## Comptes de test

| E-mail | Mot de passe |
|--------|--------------|
| chogarfils3@gmail.com | Hassouni1 |
| amina.test@souk-tchad.com | TestAmina1 |
| oumar@gmail.com | Oumar1 |

---

## Tests API automatisés (Mac)

```bash
bash scripts/phase1-test-api.sh
```

Dernier run : **8/8 OK** — backend, 8 catégories, 27 annonces, recherche, login, favoris, latence ~33 ms.

---

## Checklist manuelle iPhone

Cochez après test sur appareil physique.

### A. Réseau & démarrage

- [ ] Backend lancé : `cd backend && npm run start:dev`
- [ ] `bash scripts/check-serveur.sh` → tout vert
- [ ] iPhone et Mac sur le **même Wi‑Fi**
- [ ] Réglages iOS → Souk Tchad → **Réseau local** activé
- [ ] Profil → URL serveur = `http://<IP-Mac>:3000/api`
- [ ] Splash ~0,4 s puis accueil
- [ ] Annonces visibles en **moins de 2 s** (2ᵉ ouverture avec cache)

### B. Mode invité (sans connexion)

- [ ] Accueil : grille d’annonces (≥ 20 cartes)
- [ ] Filtre par catégorie (8 puces)
- [ ] Recherche texte (« iphone », « démo »)
- [ ] Détail d’une annonce
- [ ] **Pas** d’onglet Publier (4 onglets seulement)
- [ ] Tenter publier / message → redirection login

### C. Connexion

- [ ] Login e-mail `chogarfils3@gmail.com`
- [ ] Annonces **toujours visibles** juste après connexion (pas d’écran vide long)
- [ ] 5 onglets dont **Publier**
- [ ] Profil : carte bleue + logo (invité) / photo (connecté)

### D. Annonces

- [ ] Créer une annonce (photo + titre + prix)
- [ ] Voir dans « Mes annonces » / profil
- [ ] Modifier une annonce
- [ ] Supprimer une annonce
- [ ] Vidéo annonce (si testée) ≤ 1 min

### E. Social

- [ ] Ajouter / retirer favori
- [ ] Ouvrir une conversation depuis une annonce
- [ ] Envoyer message texte
- [ ] Message vocal (micro)
- [ ] Badge messages non lus

### F. Profil & réglages

- [ ] Changer langue (FR / AR / EN)
- [ ] Mode clair / sombre
- [ ] Politique confidentialité, CGU, Contact, À propos
- [ ] Lien bleu **Expérience Tech Sarl** → site web
- [ ] E-mail support → messagerie

### G. IA & recherche image

- [ ] Recherche par photo (caméra ou galerie)
- [ ] Traduction / amélioration texte annonce (si utilisé)

---

## Bugs / lenteurs identifiés (à valider sur iPhone)

| # | Zone | Symptôme | Gravité | Statut |
|---|------|----------|---------|--------|
| 1 | Cache login | Avant correctif : annonces lentes après connexion (cache vidé) | Haute | **Corrigé** — ne plus vider le cache public |
| 2 | 1ʳᵉ install | Premier lancement sans cache = attente réseau | Moyenne | Attendu — tirer pour rafraîchir |
| 3 | Images démo | Photos `[Démo]` via Internet (picsum) | Faible | Normal en dev |
| 4 | IP Mac | Si Wi‑Fi change, mettre à jour l’URL serveur | Moyenne | Vérifier `check-serveur.sh` |
| 5 | Push FCM | Notifications si Firebase non configuré sur iPhone | Faible | Config prod |
| 6 | Tests Flutter | `test/widget_test.dart` référence `MyApp` inexistant | Faible | CI seulement |
| 7 | Recherche image | Dépend de `GEMINI_API_KEY` valide | Moyenne | Tester sur iPhone |
| 8 | Annonces locales | Images `/uploads/...` = même réseau que le Mac | Info | Normal |

---

## Si les annonces ne s’affichent pas

1. Vérifier le backend (`npm run start:dev`)
2. Accueil → **tirer vers le bas** (rafraîchir)
3. Profil → vérifier l’URL serveur
4. Relancer : `cd mobile && bash install-sans-cable.sh`

---

## Commandes utiles

```bash
# Diagnostic réseau
bash scripts/check-serveur.sh

# Tests API phase 1
bash scripts/phase1-test-api.sh

# Annonces + comptes de test
cd backend && npm run seed:dev

# Réinstaller sur iPhone
cd mobile && bash install-sans-cable.sh
```
