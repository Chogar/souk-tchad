import { DataSource } from 'typeorm';
import { Category } from '../../entities/category.entity';
import { Listing, ListingStatus } from '../../entities/listing.entity';
import { User } from '../../entities/user.entity';
import {
  DEMO_PREFIX,
  DEMO_TARGET_COUNT,
  buildDemoListings,
} from './demo-listings.catalog';

export async function clearDevListings(dataSource: DataSource): Promise<number> {
  const result = await dataSource
    .getRepository(Listing)
    .createQueryBuilder()
    .delete()
    .where('title LIKE :prefix', { prefix: `${DEMO_PREFIX}%` })
    .execute();

  return result.affected ?? 0;
}

export async function seedDevListings(dataSource: DataSource): Promise<number> {
  const listingsRepo = dataSource.getRepository(Listing);
  const categoriesRepo = dataSource.getRepository(Category);
  const usersRepo = dataSource.getRepository(User);

  const categories = await categoriesRepo.find();
  const bySlug = new Map(categories.map((c) => [c.slug, c]));

  const demoListings = buildDemoListings(DEMO_TARGET_COUNT);
  let created = 0;
  let skipped = 0;

  for (const item of demoListings) {
    const existing = await listingsRepo.findOne({
      where: { title: item.title },
    });
    if (existing) {
      skipped++;
      continue;
    }

    const category = bySlug.get(item.categorySlug);
    const user = await usersRepo.findOne({
      where: { email: item.userEmail },
    });

    if (!category || !user) {
      console.warn(
        `⚠️  Annonce ignorée (catégorie ou utilisateur manquant) : ${item.title}`,
      );
      continue;
    }

    await listingsRepo.save(
      listingsRepo.create({
        title: item.title,
        description: item.description,
        price: item.price,
        currency: 'XAF',
        city: item.city,
        images: item.images,
        videos: [],
        status: ListingStatus.ACTIVE,
        categoryId: category.id,
        userId: user.id,
      }),
    );
    created++;
  }

  const demoTotal = await listingsRepo
    .createQueryBuilder('listing')
    .where('listing.title LIKE :prefix', { prefix: `${DEMO_PREFIX}%` })
    .getCount();

  if (skipped > 0) {
    console.log(`   (${skipped} annonce(s) déjà présentes, ignorées)`);
  }
  if (demoTotal < DEMO_TARGET_COUNT) {
    console.warn(
      `⚠️  ${demoTotal}/${DEMO_TARGET_COUNT} annonces « ${DEMO_PREFIX} » en base — relancez le seed si besoin.`,
    );
  }

  return created;
}
