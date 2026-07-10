import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../models/listing_model.dart';
import 'api_service.dart';

class ListingsService {
  ListingsService(this._api);

  final ApiService _api;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _api.client.get('/categories');
    return (response.data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListingModel>> getListings({
    String? categoryId,
    String? search,
    String? city,
  }) async {
    final response = await _api.client.get(
      '/listings',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (city != null && city.isNotEmpty) 'city': city,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingModel> getListing(String id) async {
    final response = await _api.client.get('/listings/$id');
    return ListingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ListingModel>> getMyListings() async {
    final response = await _api.client.get('/listings/mine');
    return (response.data as List<dynamic>)
        .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingModel> createListing({
    required String title,
    required String description,
    required double price,
    required String categoryId,
    String? city,
    String? customCategoryName,
  }) async {
    final response = await _api.client.post(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        if (city != null) 'city': city,
        if (customCategoryName != null && customCategoryName.isNotEmpty)
          'customCategoryName': customCategoryName,
      },
    );
    return ListingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ListingModel> uploadVideo(String listingId, XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'video.mp4';
    final formData = FormData.fromMap({
      'video': MultipartFile.fromBytes(bytes, filename: name),
    });

    final response = await _api.client.post(
      '/listings/$listingId/video',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return ListingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ListingModel> uploadImages(String listingId, List<XFile> files) async {
    final formData = FormData();
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'image_$i.jpg';
      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(bytes, filename: name),
        ),
      );
    }

    final response = await _api.client.post(
      '/listings/$listingId/images',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return ListingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ListingModel> updateListing(
    String id, {
    String? title,
    String? description,
    double? price,
    String? categoryId,
    String? city,
    String? customCategoryName,
    List<String>? images,
    List<String>? videos,
  }) async {
    final response = await _api.client.patch(
      '/listings/$id',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (categoryId != null) 'categoryId': categoryId,
        if (city != null) 'city': city,
        if (customCategoryName != null) 'customCategoryName': customCategoryName,
        if (images != null) 'images': images,
        if (videos != null) 'videos': videos,
      },
    );
    return ListingModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteListing(String id) async {
    await _api.client.delete('/listings/$id');
  }
}
