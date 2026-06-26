import '../models/listing_model.dart';
import 'api_service.dart';

class FavoritesService {
  FavoritesService(this._api);

  final ApiService _api;

  Future<List<ListingModel>> getFavorites() async {
    final response = await _api.client.get('/favorites');
    return (response.data as List<dynamic>)
        .map((fav) => ListingModel.fromJson(
              (fav as Map<String, dynamic>)['listing'] as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<bool> isFavorite(String listingId) async {
    final response = await _api.client.get('/favorites/$listingId/check');
    return response.data as bool;
  }

  Future<void> add(String listingId) async {
    await _api.client.post('/favorites/$listingId');
  }

  Future<void> remove(String listingId) async {
    await _api.client.delete('/favorites/$listingId');
  }
}
