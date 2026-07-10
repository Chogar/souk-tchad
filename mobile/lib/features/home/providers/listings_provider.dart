import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/server_config_provider.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/listings_bootstrap.dart';
import '../../../core/services/listings_service.dart';
import '../../../core/utils/search_utils.dart';

class ListingsFilter {
  const ListingsFilter({this.categoryId, this.search = ''});

  final String? categoryId;
  final String search;

  @override
  bool operator ==(Object other) =>
      other is ListingsFilter &&
      other.categoryId == categoryId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(categoryId, search);
}

const defaultListingsFilter = ListingsFilter();

/// Incrémenté après chaque sync catalogue → force le rafraîchissement de l'UI.
final catalogVersionProvider =
    NotifierProvider<CatalogVersionNotifier, int>(CatalogVersionNotifier.new);

class CatalogVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

void bumpCatalogVersion(dynamic ref) {
  ref.read(catalogVersionProvider.notifier).bump();
}

Map<String, dynamic> listingToCacheJson(ListingModel listing) => {
      'id': listing.id,
      'title': listing.title,
      'description': listing.description,
      'price': listing.price,
      'currency': listing.currency,
      'city': listing.city,
      'images': listing.images,
      'videos': listing.videos,
      'status': listing.status,
      'category': {
        'id': listing.category.id,
        'name': listing.category.name,
        'slug': listing.category.slug,
        'icon': listing.category.icon,
      },
      'user': {
        'id': listing.user.id,
        'email': listing.user.email,
        'name': listing.user.name,
        'avatarUrl': listing.user.avatarUrl,
        'phone': listing.user.phone,
        'plan': listing.user.plan,
        'isEmailVerified': listing.user.isEmailVerified,
      },
      'createdAt': listing.createdAt.toIso8601String(),
      if (listing.customCategoryName != null)
        'customCategoryName': listing.customCategoryName,
    };

List<ListingModel> _dedupeListings(List<ListingModel> listings) {
  final unique = <String, ListingModel>{};
  for (final listing in listings) {
    unique[listing.id] = listing;
  }
  return unique.values.toList();
}

List<ListingModel> _applyLocalFilters(
  List<ListingModel> listings,
  ListingsFilter filter,
) {
  var result = listings;
  if (filter.categoryId != null) {
    result = result
        .where((listing) => listing.category.id == filter.categoryId)
        .toList();
  }
  if (filter.search.isNotEmpty) {
    result = filterAndRankListings(result, filter.search);
  }
  return result;
}

Future<List<ListingModel>> _loadFromCache(
  CacheService cache,
  ListingsFilter filter,
) async {
  final rows = await cache.getCachedListings();
  if (rows.isEmpty) return [];
  final listings = rows.map((entry) => ListingModel.fromJson(entry)).toList();
  final deduped = _dedupeListings(listings);
  if (filter.categoryId == null && filter.search.isEmpty) {
    ListingsBootstrap.updateListings(deduped);
  }
  return _applyLocalFilters(deduped, filter);
}

Future<List<ListingModel>> _fetchFromNetwork(
  ListingsService service,
  CacheService cache,
  ListingsFilter filter,
) async {
  final listings = await service.getListings(categoryId: filter.categoryId);

  if (filter.categoryId == null && filter.search.isEmpty) {
    final deduped = _dedupeListings(listings);
    ListingsBootstrap.updateListings(deduped);
    await cache.cacheListings(
      deduped.map(listingToCacheJson).toList(),
    );
  }

  return _applyLocalFilters(_dedupeListings(listings), filter);
}

String _catalogFingerprint(List<ListingModel>? listings) {
  if (listings == null || listings.isEmpty) return '';
  final parts = listings.map((l) => '${l.id}:${l.images.length}').toList()
    ..sort();
  return '${parts.length}:${parts.join('|')}';
}

/// Sync réseau : ne bump l'UI que si le catalogue a vraiment changé.
Future<void> _syncCatalogQuietly({
  required dynamic ref,
  required ListingsService service,
  required CacheService cache,
  required ListingsFilter filter,
}) async {
  try {
    final before = _catalogFingerprint(ListingsBootstrap.listings);
    await _fetchFromNetwork(service, cache, filter);
    final after = _catalogFingerprint(ListingsBootstrap.listings);
    if (before != after) {
      bumpCatalogVersion(ref);
    }
  } catch (_) {}
}

void _scheduleBackgroundSync(
  dynamic ref,
  ListingsService service,
  CacheService cache,
  ListingsFilter filter,
) {
  unawaited(
    _syncCatalogQuietly(
      ref: ref,
      service: service,
      cache: cache,
      filter: filter,
    ),
  );
}

final listingsProvider =
    FutureProvider.family<List<ListingModel>, ListingsFilter>((ref, filter) async {
  ref.keepAlive();
  ref.watch(catalogVersionProvider);

  final service = ref.read(listingsServiceProvider);
  final cache = ref.read(cacheServiceProvider);

  final boot = ListingsBootstrap.listings;
  if (boot != null && boot.isNotEmpty) {
    final fromMemory = _applyLocalFilters(_dedupeListings(boot), filter);
    if (fromMemory.isNotEmpty) {
      unawaited(
        () async {
          try {
            await ref.read(apiBaseUrlProvider.future);
            await _syncCatalogQuietly(
              ref: ref,
              service: service,
              cache: cache,
              filter: filter,
            );
          } catch (_) {}
        }(),
      );
      return fromMemory;
    }
  }

  // Attendre l'URL serveur seulement si pas de cache mémoire.
  await ref.watch(apiBaseUrlProvider.future);

  final cached = await _loadFromCache(cache, filter);
  if (cached.isNotEmpty) {
    _scheduleBackgroundSync(ref, service, cache, filter);
    return cached;
  }

  return _fetchFromNetwork(service, cache, filter);
});
