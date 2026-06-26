import { Injectable } from '@nestjs/common';
import { ListingStatus } from '../../entities/listing.entity';

const FORBIDDEN_WORDS = [
  'drogue',
  'cannabis',
  'arme',
  'pistolet',
  'fusil',
  'arnaque',
  'escroquerie',
];

const CATEGORY_PRICE_RULES: Record<
  string,
  { min: number; max: number; rentalMin?: number; rentalMax?: number }
> = {
  immobilier: {
    min: 500_000,
    max: 5_000_000_000,
    rentalMin: 5_000,
    rentalMax: 50_000_000,
  },
  automobiles: { min: 100_000, max: 500_000_000 },
  electronique: { min: 5_000, max: 50_000_000 },
};

const RENTAL_KEYWORDS = ['louer', 'location', 'loyer', 'à louer', 'a louer'];

@Injectable()
export class ModerationService {
  moderateListing(input: {
    title: string;
    description: string;
    price: number;
    categorySlug: string;
  }): { status: ListingStatus; reason?: string } {
    const text = `${input.title} ${input.description}`.toLowerCase();

    for (const word of FORBIDDEN_WORDS) {
      if (text.includes(word)) {
        return {
          status: ListingStatus.MODERATED,
          reason: `Contenu interdit détecté : ${word}`,
        };
      }
    }

    const rule = CATEGORY_PRICE_RULES[input.categorySlug];
    if (rule) {
      const isRental = RENTAL_KEYWORDS.some((word) => text.includes(word));
      const min = isRental && rule.rentalMin != null ? rule.rentalMin : rule.min;
      const max = isRental && rule.rentalMax != null ? rule.rentalMax : rule.max;

      if (input.price < min || input.price > max) {
        return {
          status: ListingStatus.MODERATED,
          reason: isRental
            ? 'Loyer mensuel incohérent pour cette catégorie'
            : 'Prix incohérent pour cette catégorie',
        };
      }
    }

    return { status: ListingStatus.ACTIVE };
  }
}
