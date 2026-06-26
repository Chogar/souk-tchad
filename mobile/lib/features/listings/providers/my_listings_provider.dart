import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/app_providers.dart';

final myListingsProvider = FutureProvider<List<ListingModel>>((ref) async {
  return ref.read(listingsServiceProvider).getMyListings();
});
