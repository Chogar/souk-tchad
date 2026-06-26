import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/server_config_provider.dart';
import '../../../core/services/listings_bootstrap.dart';
import 'listings_provider.dart';

Future<List<CategoryModel>> _fetchCategories(dynamic ref) async {
  final service = ref.read(listingsServiceProvider);
  final cache = ref.read(cacheServiceProvider);
  final categories = await service.getCategories();
  ListingsBootstrap.updateCategories(categories);
  try {
    await cache.cacheCategories(CategoryModel.toCacheJsonList(categories));
  } catch (_) {
    // Le cache ne doit pas bloquer l'affichage des catégories.
  }
  return categories;
}

Future<void> _fetchCategoriesInBackground(dynamic ref) async {
  try {
    await _fetchCategories(ref);
  } catch (_) {}
}

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.keepAlive();
  ref.watch(catalogVersionProvider);
  await ref.watch(apiBaseUrlProvider.future);

  final boot = ListingsBootstrap.categories;
  if (boot != null && boot.isNotEmpty) {
    unawaited(_fetchCategoriesInBackground(ref));
    return boot;
  }

  List<CategoryModel> cached = [];
  try {
    final cache = ref.read(cacheServiceProvider);
    final rows = await cache.getCachedCategories();
    if (rows.isNotEmpty) {
      cached = rows.map((entry) => CategoryModel.fromJson(entry)).toList();
    }
  } catch (_) {}

  if (cached.isNotEmpty) {
    unawaited(_fetchCategoriesInBackground(ref));
    return cached;
  }

  return _fetchCategories(ref);
});
