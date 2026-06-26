import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import 'app_providers.dart';

final favoritesProvider = FutureProvider<List<ListingModel>>((ref) async {
  if (ref.read(authStateProvider).value == null) return [];
  final service = ref.read(favoritesServiceProvider);
  try {
    final favorites = await service.getFavorites();
    await ref.read(cacheServiceProvider).cacheFavorites(
          favorites.map((l) => {'listing': _listingToJson(l)}).toList(),
        );
    return favorites;
  } catch (_) {
    final cached = await ref.read(cacheServiceProvider).getCachedFavorites();
    return cached
        .map((f) => ListingModel.fromJson(f['listing'] as Map<String, dynamic>))
        .toList();
  }
});

Map<String, dynamic> _listingToJson(ListingModel l) => {
      'id': l.id,
      'title': l.title,
      'description': l.description,
      'price': l.price,
      'currency': l.currency,
      'city': l.city,
      'images': l.images,
      'videos': l.videos,
      'status': l.status,
      'category': {
        'id': l.category.id,
        'name': l.category.name,
        'slug': l.category.slug,
        'icon': l.category.icon,
      },
      'user': {
        'id': l.user.id,
        'email': l.user.email,
        'name': l.user.name,
        'avatarUrl': l.user.avatarUrl,
        'phone': l.user.phone,
        'plan': l.user.plan,
        'isEmailVerified': l.user.isEmailVerified,
      },
      'createdAt': l.createdAt.toIso8601String(),
    };

final favoriteIdsProvider =
    NotifierProvider<FavoriteIdsNotifier, Set<String>>(FavoriteIdsNotifier.new);

class FavoriteIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.listen(authStateProvider, (previous, next) {
      final prevId = previous?.value?.id;
      final nextId = next.value?.id;
      if (next.value != null) {
        if (prevId != nextId) {
          ref.invalidate(favoritesProvider);
        }
        Future.microtask(load);
      } else {
        state = {};
        ref.invalidate(favoritesProvider);
      }
    }, fireImmediately: true);
    return {};
  }

  bool isFavorite(String listingId) => state.contains(listingId);

  Future<void> load() async {
    if (ref.read(authStateProvider).value == null) {
      state = {};
      return;
    }

    try {
      final listings = await ref.read(favoritesServiceProvider).getFavorites();
      state = listings.map((listing) => listing.id).toSet();
    } catch (_) {
      // Garde l'état local si le rechargement échoue.
    }
  }

  void clear() => state = {};

  Future<void> toggle(String listingId) async {
    final service = ref.read(favoritesServiceProvider);
    final wasFavorite = state.contains(listingId);

    if (wasFavorite) {
      state = Set<String>.from(state)..remove(listingId);
      try {
        await service.remove(listingId);
      } catch (_) {
        state = Set<String>.from(state)..add(listingId);
        rethrow;
      }
    } else {
      state = Set<String>.from(state)..add(listingId);
      try {
        await service.add(listingId);
      } catch (e) {
        state = Set<String>.from(state)..remove(listingId);
        rethrow;
      }
    }

    ref.invalidate(favoritesProvider);
  }
}
