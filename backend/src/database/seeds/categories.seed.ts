import { DataSource } from 'typeorm';
import { Category } from '../../entities/category.entity';

export const CATEGORIES_SEED = [
  { name: 'Automobiles & Véhicules', slug: 'automobiles', icon: '🚗', order: 1 },
  { name: 'Immobilier', slug: 'immobilier', icon: '🏢', order: 2 },
  {
    name: 'Téléphones & Électronique',
    slug: 'electronique',
    icon: '📱',
    order: 3,
  },
  { name: 'Emplois', slug: 'emplois', icon: '💼', order: 4 },
  { name: 'Services', slug: 'services', icon: '🛠️', order: 5 },
  { name: 'Meubles & Maison', slug: 'meubles', icon: '🛋️', order: 6 },
  { name: 'Vêtements & Mode', slug: 'mode', icon: '👕', order: 7 },
  { name: 'Animaux & Élevage', slug: 'animaux', icon: '🐫', order: 8 },
  { name: 'Autre', slug: 'autre', icon: '📦', order: 9 },
];

export async function seedCategories(dataSource: DataSource): Promise<void> {
  const repo = dataSource.getRepository(Category);
  const count = await repo.count();
  if (count === 0) {
    await repo.save(CATEGORIES_SEED.map((item) => repo.create(item)));
    return;
  }

  const autre = await repo.findOne({ where: { slug: 'autre' } });
  if (!autre) {
    await repo.save(
      repo.create({ name: 'Autre', slug: 'autre', icon: '📦', order: 9 }),
    );
  }
}
