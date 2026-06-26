import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  ApiService({String? baseUrl}) {
    _baseUrl = baseUrl ?? ApiConstants.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          final isPublicAuth = options.path.contains('/auth/login') ||
              options.path.contains('/auth/register') ||
              options.path.contains('/auth/google');

          if (!isPublicAuth) {
            final token = await _getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;
  late String _baseUrl;
  static const _tokenKey = 'auth_token';

  Dio get client => _dio;
  String get baseUrl => _baseUrl;

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> _getToken() => getToken();

  String mediaUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = _baseUrl.replaceAll('/api', '');
    return '$base$path';
  }
}
