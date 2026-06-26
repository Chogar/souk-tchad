import '../models/listing_model.dart';

const _stopWords = {
  'le',
  'la',
  'les',
  'un',
  'une',
  'des',
  'de',
  'du',
  'et',
  'ou',
  'pour',
  'avec',
  'en',
  'au',
  'aux',
  'sur',
  'par',
  'produit',
  'article',
  'objet',
  'chose',
  'item',
  'the',
  'and',
};

String normalizeSearchText(String input) {
  var text = input.toLowerCase().trim();
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  accents.forEach((from, to) {
    text = text.replaceAll(from, to);
  });
  return text;
}

List<String> extractSearchTerms(String input) {
  final normalized = normalizeSearchText(input);
  final rawTerms = normalized
      .split(RegExp(r'[\s,;.+/\\|]+'))
      .map((term) => term.replaceAll(RegExp(r"[^a-z0-9'-]"), ''))
      .where((term) => term.length > 1 && !_stopWords.contains(term))
      .toList();

  return rawTerms.toSet().toList();
}

int scoreListing(ListingModel listing, List<String> terms) {
  if (terms.isEmpty) return 0;

  final title = normalizeSearchText(listing.title);
  final description = normalizeSearchText(listing.description);
  final category = normalizeSearchText(listing.category.name);
  final titleWords =
      title.split(RegExp(r'\s+')).where((word) => word.length > 1).toList();

  var score = 0;
  for (final term in terms) {
    if (title.contains(term)) {
      score += 12;
      continue;
    }

    if (titleWords.any(
      (word) =>
          word.startsWith(term) ||
          term.startsWith(word) ||
          (term.length >= 4 && word.contains(term)),
    )) {
      score += 8;
      continue;
    }

    if (description.contains(term)) {
      score += 4;
      continue;
    }

    if (category.contains(term)) {
      score += 3;
    }
  }

  return score;
}

List<ListingModel> filterAndRankListings(
  List<ListingModel> listings,
  String search,
) {
  final query = search.trim();
  if (query.isEmpty) return listings;

  final terms = extractSearchTerms(query);
  if (terms.isEmpty) {
    final normalizedQuery = normalizeSearchText(query);
    return listings
        .where((listing) {
          final haystack = normalizeSearchText(
            '${listing.title} ${listing.description} ${listing.category.name}',
          );
          return haystack.contains(normalizedQuery);
        })
        .toList();
  }

  final scored = <MapEntry<ListingModel, int>>[];
  for (final listing in listings) {
    final score = scoreListing(listing, terms);
    if (score > 0) {
      scored.add(MapEntry(listing, score));
    }
  }

  if (scored.isEmpty) {
    final looseTerms = terms.where((term) => term.length >= 3).toList();
    for (final listing in listings) {
      final score = scoreListing(listing, looseTerms);
      if (score > 0) {
        scored.add(MapEntry(listing, score));
      }
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((entry) => entry.key).toList();
}
