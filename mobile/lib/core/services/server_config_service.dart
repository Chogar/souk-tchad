import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ServerConfigService {
  static const _urlKey = 'api_base_url';

  String normalizeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return ApiConstants.baseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // En release : HTTPS uniquement (sauf localhost pour tests locaux).
    if (kReleaseMode) {
      final host = Uri.tryParse(url)?.host ?? '';
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (!isLocal && url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
    }
    url = url.replaceAll(RegExp(r'/+$'), '');
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  Future<String> loadBaseUrl() async {
    final builtIn = normalizeUrl(ApiConstants.baseUrl);
    // En release : toujours l’URL compilée (pas d’override utilisateur).
    if (kReleaseMode) {
      return builtIn;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_urlKey);

    if (saved == null || saved.trim().isEmpty) {
      await prefs.setString(_urlKey, builtIn);
      return builtIn;
    }

    final normalized = normalizeUrl(saved);
    final builtHost = Uri.tryParse(builtIn)?.host;
    final savedHost = Uri.tryParse(normalized)?.host;

    final savedIsLocalhost = savedHost == '127.0.0.1' || savedHost == 'localhost';
    final builtIsLan = builtHost != null && builtHost.startsWith('192.168.');

    if (savedIsLocalhost && builtIsLan) {
      await prefs.setString(_urlKey, builtIn);
      return builtIn;
    }

    if (builtIsLan &&
        savedHost != null &&
        savedHost.startsWith('192.168.') &&
        builtHost != savedHost) {
      await prefs.setString(_urlKey, builtIn);
      return builtIn;
    }

    return normalized;
  }

  Future<void> saveBaseUrl(String raw) async {
    if (kReleaseMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, normalizeUrl(raw));
  }

  Future<void> testConnection(String raw) async {
    final url = normalizeUrl(raw);
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    await dio.get('/listings');
  }
}
