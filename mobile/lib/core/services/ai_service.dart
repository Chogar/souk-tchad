import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_search_result.dart';
import '../utils/image_search_prep.dart';
import 'api_service.dart';

class AiService {
  AiService(this._api);

  final ApiService _api;

  Future<String> translate(String text, {String targetLang = 'fr'}) async {
    final response = await _api.client.post(
      '/ai/translate',
      data: {'text': text, 'targetLang': targetLang},
    );
    return response.data as String;
  }

  Future<Map<String, String>> improveListing({
    required String title,
    required String description,
  }) async {
    final response = await _api.client.post(
      '/ai/improve-listing',
      data: {'title': title, 'description': description},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'title': data['title'] as String,
      'description': data['description'] as String,
    };
  }

  Future<ImageSearchResult> searchByImage(
    XFile file, {
    Uint8List? preparedBytes,
  }) async {
    final bytes = preparedBytes ?? await prepareImageForSearch(file);
    final filename = 'search.jpg';
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(_imageMimeType(filename)),
      ),
    });

    final response = await _api.client.post(
      '/ai/search-by-image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );
    final data = response.data as Map<String, dynamic>;
    final result = ImageSearchResult.fromJson(data);
    if (result.keywords.isEmpty) {
      throw Exception('Aucun mot-clé détecté');
    }
    return result;
  }

  static String _imageMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
