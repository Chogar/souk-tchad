import '../models/category_model.dart';
import '../models/listing_model.dart';
import 'cache_service.dart';

/// Cache mémoire pour afficher les annonces sans attendre SQLite/réseau.
class ListingsBootstrap {
  static List<ListingModel>? _listings;
  static List<CategoryModel>? _categories;

  static List<ListingModel>? get listings => _listings;
  static List<CategoryModel>? get categories => _categories;

  static Future<void> warm(CacheService cache) async {
    try {
      final rows = await cache.getCachedListings();
      if (rows.isNotEmpty) {
        _listings = rows
            .map((entry) => ListingModel.fromJson(entry))
            .toList();
      }
      final categoryRows = await cache.getCachedCategories();
      if (categoryRows.isNotEmpty) {
        _categories = categoryRows
            .map((entry) => CategoryModel.fromJson(entry))
            .toList();
      }
    } catch (_) {}
  }

  static void updateListings(List<ListingModel> listings) {
    _listings = listings;
  }

  static void updateCategories(List<CategoryModel> categories) {
    _categories = categories;
  }
}
