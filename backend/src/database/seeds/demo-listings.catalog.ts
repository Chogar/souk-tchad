export const DEMO_PREFIX = '[Démo]';

export const DEMO_TARGET_COUNT = 100;

export const DEMO_USER_EMAILS = [
  'chogarfils3@gmail.com',
  'amina.test@souk-tchad.com',
  'oumar@gmail.com',
] as const;

export const CHAD_CITIES = [
  "N'Djamena",
  'Moundou',
  'Sarh',
  'Abéché',
  'Biltine',
  'Mongo',
  'Doba',
  'Koumra',
  'Faya-Largeau',
  'Pala',
  'Am-Timan',
  'Ati',
  'Massaguet',
  'Laï',
  'Goundi',
] as const;

type CategoryCatalog = {
  slug: string;
  titles: string[];
  descriptions: string[];
  images: string[];
  priceMin: number;
  priceMax: number;
};

/** Images stables, affichage direct mobile (évite les blocages Unsplash). */
const demoImg = (category: string, index: number) =>
  `https://picsum.photos/seed/souk-${category}-${index}/720/720`;

const imagesFor = (slug: string) =>
  [0, 1, 2, 3, 4, 5].map((i) => demoImg(slug, i));

export const CATEGORY_CATALOG: CategoryCatalog[] = [
  {
    slug: 'automobiles',
    titles: [
      'Toyota Hilux',
      'Moto Yamaha 125',
      'Peugeot 307',
      'Land Cruiser V8',
      'Camionnette Isuzu',
      'Moto Honda CB',
      'Suzuki Swift',
      'Pick-up Nissan Navara',
      'Vélo électrique',
      'Remorque agricole',
      'Toyota Corolla',
      'Moto TVS Apache',
      'Bus minibus 18 places',
    ],
    descriptions: [
      'Véhicule en bon état, papiers en règle. Entretien régulier, négociable.',
      'Moteur fiable, climatisation fonctionnelle. Visible sur rendez-vous.',
      'Kilométrage certifié, carrosserie propre. Idéal pour la ville.',
      '4x4 robuste, pneus récents. Parfait pour routes et pistes.',
      'Vendu pour départ ou changement de véhicule. Essai possible.',
    ],
    images: imagesFor('automobiles'),
    priceMin: 350000,
    priceMax: 18000000,
  },
  {
    slug: 'immobilier',
    titles: [
      'Appartement F3',
      'Villa R+1 à louer',
      'Terrain 500 m²',
      'Studio meublé',
      'Maison 4 chambres',
      'Bureau commercial',
      'Parcelle titrée',
      'Duplex moderne',
      'Local boutique',
      'Appartement F2 Moursal',
      'Villa avec jardin',
      'Terrain viabilisé',
      'Chambre individuelle',
    ],
    descriptions: [
      'Quartier calme, accès facile. Disponible immédiatement.',
      'Titre foncier disponible. Visite sur rendez-vous.',
      'Proximité marché et écoles. Loyer ou vente selon offre.',
      'Bien entretenu, charges claires. Idéal famille ou professionnel.',
      'Sécurisé, parking possible. Négociation ouverte.',
    ],
    images: imagesFor('immobilier'),
    priceMin: 45000,
    priceMax: 12000000,
  },
  {
    slug: 'electronique',
    titles: [
      'iPhone 14 Pro',
      'Samsung Galaxy A54',
      'PC portable HP i5',
      'MacBook Air M1',
      'Télévision Samsung 55"',
      'Écouteurs Bluetooth',
      'Tablette iPad',
      'Console PlayStation',
      'Appareil photo Canon',
      'Imprimante HP',
      'Routeur Wi-Fi',
      'Montre connectée',
      'Enceinte JBL',
    ],
    descriptions: [
      'État impeccable, accessoires inclus. Débloqué et testé.',
      'Batterie en bon état, boîte d\'origine. Aucune rayure majeure.',
      'Parfait pour bureautique, études ou gaming léger.',
      'Garantie constructeur encore valable sur certains modèles.',
      'Vendu pour mise à niveau. Facture disponible sur demande.',
    ],
    images: imagesFor('electronique'),
    priceMin: 25000,
    priceMax: 950000,
  },
  {
    slug: 'emplois',
    titles: [
      'Chauffeur-livreur',
      'Comptable junior',
      'Secrétaire bilingue',
      'Vendeur boutique',
      'Technicien informatique',
      'Aide-cuisinier',
      'Gardien de nuit',
      'Commercial terrain',
      'Infirmier(ère)',
      'Maçon qualifié',
      'Réceptionniste hôtel',
      'Assistant administratif',
      'Livreur moto',
    ],
    descriptions: [
      'Poste à pourvoir rapidement. CV et lettre de motivation requis.',
      'Contrat à durée déterminée avec possibilité de CDI.',
      'Expérience appréciée mais débutants motivés acceptés.',
      'Salaire selon profil + primes sur objectifs.',
      'Lieu de travail en ville, horaires définis.',
    ],
    images: imagesFor('emplois'),
    priceMin: 80000,
    priceMax: 450000,
  },
  {
    slug: 'services',
    titles: [
      'Réparation climatisation',
      'Cours de français et arabe',
      'Plomberie à domicile',
      'Coiffure à domicile',
      'Dépannage électrique',
      'Nettoyage bureaux',
      'Traduction documents',
      'Installation antenne',
      'Peinture bâtiment',
      'Réparation smartphones',
      'Transport colis',
      'Jardinage et entretien',
      'Déménagement local',
    ],
    descriptions: [
      'Intervention rapide en ville et environs. Devis gratuit.',
      'Professionnel expérimenté, références disponibles.',
      'Service fiable, tarifs transparents. Paiement après travail.',
      'Disponible en semaine et week-end sur rendez-vous.',
      'Matériel fourni. Satisfaction garantie.',
    ],
    images: imagesFor('services'),
    priceMin: 5000,
    priceMax: 75000,
  },
  {
    slug: 'meubles',
    titles: [
      'Canapé 3 places',
      'Réfrigérateur LG',
      'Table à manger',
      'Lit double avec matelas',
      'Armoire 3 portes',
      'Machine à laver',
      'Bureau en bois',
      'Chaises salon (lot de 4)',
      'Micro-ondes Samsung',
      'Étagère murale',
      'Cuisinière à gaz',
      'Ventilateur sur pied',
      'Tapis salon',
    ],
    descriptions: [
      'Très bon état général. À récupérer sur place.',
      'Fonctionne parfaitement. Vendu pour déménagement.',
      'Matériaux solides, entretien régulier.',
      'Dimensions sur demande. Photos récentes.',
      'Prix légèrement négociable pour vente rapide.',
    ],
    images: imagesFor('meubles'),
    priceMin: 15000,
    priceMax: 350000,
  },
  {
    slug: 'mode',
    titles: [
      'Boubou brodé traditionnel',
      'Sneakers Nike Air',
      'Sac à main cuir',
      'Costume homme',
      'Robe soirée',
      'Baskets Adidas',
      'Montre Casio',
      'Pagne wax (6 m)',
      'Chaussures ville',
      'Ensemble enfant',
      'Ceinture artisanale',
      'Lunettes de soleil',
      'Bijoux fantaisie',
    ],
    descriptions: [
      'Article propre, peu porté. Taille indiquée dans le titre.',
      'Authenticité garantie pour les marques. Facture si disponible.',
      'Couleurs vives, confection soignée.',
      'Idéal cérémonie ou usage quotidien.',
      'Échange possible sur certains articles.',
    ],
    images: imagesFor('mode'),
    priceMin: 8000,
    priceMax: 120000,
  },
  {
    slug: 'animaux',
    titles: [
      'Chèvres locales (lot)',
      'Poules pondeuses',
      'Bœufs de trait',
      'Moutons (lot de 3)',
      'Poussins vaccinés',
      'Chameaux d\'élevage',
      'Porcs locaux',
      'Canards fermiers',
      'Lapins reproducteurs',
      'Abeilles (ruche)',
      'Poissons tilapia',
      'Âne de transport',
      'Pigeons reproducteurs',
    ],
    descriptions: [
      'Animaux en bonne santé, élevage local. Vaccination à jour.',
      'Vente en lot ou à l\'unité selon besoin.',
      'Livraison possible dans la région sur accord.',
      'Alimentation et conseils fournis pour nouveaux éleveurs.',
      'Prix négociable pour achat en quantité.',
    ],
    images: imagesFor('animaux'),
    priceMin: 12000,
    priceMax: 650000,
  },
];

export type DemoListingSeed = {
  title: string;
  description: string;
  price: number;
  city: string;
  categorySlug: string;
  userEmail: string;
  images: string[];
};

function pick<T>(items: readonly T[], index: number): T {
  return items[index % items.length]!;
}

function priceInRange(min: number, max: number, index: number): number {
  const span = max - min;
  const step = Math.floor(span / 17);
  const raw = min + (index % 17) * step;
  return Math.round(raw / 500) * 500;
}

export function buildDemoListings(count = DEMO_TARGET_COUNT): DemoListingSeed[] {
  const listings: DemoListingSeed[] = [];
  let globalIndex = 0;

  while (listings.length < count) {
    for (const category of CATEGORY_CATALOG) {
      if (listings.length >= count) break;

      const localIndex = Math.floor(globalIndex / CATEGORY_CATALOG.length);
      const variant = listings.filter((l) => l.categorySlug === category.slug)
        .length;

      const baseTitle = pick(category.titles, variant);
      const yearOrSize =
        category.slug === 'automobiles'
          ? ` ${2015 + (variant % 10)}`
          : category.slug === 'immobilier'
            ? variant % 2 === 0
              ? ' — location'
              : ' — vente'
            : '';

      const title = `${DEMO_PREFIX} ${baseTitle}${yearOrSize}`;

      listings.push({
        title,
        description: pick(category.descriptions, variant),
        price: priceInRange(category.priceMin, category.priceMax, variant),
        city: pick(CHAD_CITIES, globalIndex),
        categorySlug: category.slug,
        userEmail: pick(DEMO_USER_EMAILS, globalIndex),
        images: [
          pick(category.images, variant),
          pick(category.images, variant + 1),
        ],
      });

      globalIndex++;
    }
  }

  return listings.slice(0, count);
}
