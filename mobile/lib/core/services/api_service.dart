import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  ApiService({String? baseUrl}) {
    _baseUrl = baseUrl ?? ApiConstants.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        // Réseaux mobiles lents (opérateurs Tchad) + démarrage à froid du
        // serveur cPanel (~4 s) : timeouts larges sinon l'app abandonne.
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(_RetryOnErrorInterceptor(() => _dio));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          final isPublicAuth = options.path.contains('/auth/login') ||
              options.path.contains('/auth/register') ||
              options.path.contains('/auth/google') ||
              options.path.contains('/auth/send-registration-otp') ||
              options.path.contains('/auth/verify-registration-otp') ||
              options.path.contains('/auth/complete-registration');

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

    _ready = _hydrateToken();
  }

  late final Dio _dio;
  late String _baseUrl;
  static const _tokenKey = 'auth_token';

  /// Bloque la réhydratation disque pour TOUTES les instances (après logout).
  static bool _blockDiskHydration = false;

  /// Secure storage mobile uniquement — sur web le plugin n’est pas fiable.
  static final FlutterSecureStorage? _secureStorage = kIsWeb
      ? null
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  String? _memoryToken;
  Future<void>? _ready;

  Dio get client => _dio;
  String get baseUrl => _baseUrl;

  void updateBaseUrl(String url) {
    if (url.isEmpty || url == _baseUrl) return;
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  Future<void> _hydrateToken() async {
    if (_blockDiskHydration) return;
    try {
      if (_secureStorage != null) {
        final existing = await _secureStorage!.read(key: _tokenKey);
        if (_blockDiskHydration) return;
        if (existing != null && existing.isNotEmpty) {
          _memoryToken = existing;
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      if (_blockDiskHydration) return;
      final legacy = prefs.getString(_tokenKey);
      if (legacy == null || legacy.isEmpty) return;

      _memoryToken = legacy;
      if (_secureStorage != null) {
        try {
          await _secureStorage!.write(key: _tokenKey, value: legacy);
          await prefs.remove(_tokenKey);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> saveToken(String token) async {
    _blockDiskHydration = false;
    _memoryToken = token;

    if (_secureStorage != null) {
      try {
        await _secureStorage!.write(key: _tokenKey, value: token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        return;
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Coupe la session en mémoire tout de suite (sync).
  void invalidateSession() {
    _blockDiskHydration = true;
    _memoryToken = null;
  }

  Future<void> clearToken() async {
    invalidateSession();
    if (_secureStorage != null) {
      try {
        await _secureStorage!
            .delete(key: _tokenKey)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2));
      await prefs.remove(_tokenKey).timeout(const Duration(seconds: 2));
    } catch (_) {}
    _memoryToken = null;
  }

  Future<String?> getToken() async {
    await (_ready ?? Future.value());
    if (_blockDiskHydration) return null;
    if (_memoryToken != null) return _memoryToken;

    if (_secureStorage != null) {
      try {
        final token = await _secureStorage!.read(key: _tokenKey);
        if (_blockDiskHydration) return null;
        if (token != null && token.isNotEmpty) {
          _memoryToken = token;
          return token;
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_blockDiskHydration) return null;
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        _memoryToken = token;
      }
      return _memoryToken;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getToken() => getToken();

  /// URL média. Les chemins chat/voix exigent un JWT (?token=).
  String mediaUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = _baseUrl.replaceAll('/api', '');
    var url = '$base$path';
    final isPrivate = path.contains('/uploads/chat/') ||
        path.contains('/uploads/voice/') ||
        path.contains('/uploads/payments/');
    if (isPrivate && _memoryToken != null && _memoryToken!.isNotEmpty) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}token=${Uri.encodeQueryComponent(_memoryToken!)}';
    }
    return url;
  }
}

/// Réessaie automatiquement les GET échoués sur erreur réseau/timeout :
/// indispensable sur les réseaux mobiles instables (coupures brèves).
class _RetryOnErrorInterceptor extends Interceptor {
  _RetryOnErrorInterceptor(this._dioGetter);

  final Dio Function() _dioGetter;
  static const _maxRetries = 2;
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 3)];

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (!_shouldRetry(err) || attempt >= _maxRetries) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(_retryDelays[attempt]);

    final options = err.requestOptions;
    options.extra['retry_attempt'] = attempt + 1;
    try {
      final response = await _dioGetter().fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }
}
