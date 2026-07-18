import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/api_constants.dart';
import '../errors/google_sign_in_canceled.dart';
import '../models/user_model.dart';
import '../utils/google_config.dart';
import 'api_service.dart';

class AuthService {
  AuthService(this._api);

  final ApiService _api;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Partagé entre instances (ApiService peut être recréé).
  static bool _googleInitialized = false;
  static Future<void>? _googleInitFuture;

  /// Initialise Google Sign-In une seule fois (idempotent).
  Future<void> initGoogle() async {
    if (_googleInitialized) return;
    if (_googleInitFuture != null) {
      await _googleInitFuture;
      return;
    }

    _googleInitFuture = () async {
      final iosClientId = ApiConstants.googleClientId;
      final webClientId = ApiConstants.googleServerClientId;

      if (kIsWeb) {
        // Sur le web, clientId = OAuth « Application Web ».
        final webId =
            webClientId.isNotEmpty ? webClientId : iosClientId;
        await _googleSignIn.initialize(
          clientId: webId.isNotEmpty ? webId : null,
        );
      } else {
        // iOS/Android : client iOS + serverClientId Web (pour idToken).
        await _googleSignIn.initialize(
          clientId: iosClientId.isNotEmpty ? iosClientId : null,
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );
      }
      _googleInitialized = true;
    }();

    try {
      await _googleInitFuture;
    } catch (e) {
      _googleInitFuture = null;
      final message = e.toString().toLowerCase();
      if (message.contains('already been called') ||
          message.contains('already initialized')) {
        _googleInitialized = true;
        return;
      }
      rethrow;
    }
  }

  /// Affiche le sélecteur de comptes sans révoquer l'accès (évite les bugs).
  Future<void> _showAccountPicker() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<GoogleSignInAccount> _authenticate({
    required List<String> scopes,
  }) async {
    await initGoogle();
    await _showAccountPicker();

    try {
      return await _googleSignIn.authenticate(scopeHint: scopes);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCanceled();
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw StateError('GOOGLE_INVALID_CLIENT');
      }
      rethrow;
    }
  }

  Future<({String message, String email, String? devCode})> sendRegistrationOtp(
    String email,
  ) async {
    final response = await _api.client.post(
      '/auth/send-registration-otp',
      data: {'email': email.trim().toLowerCase()},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      message: data['message'] as String? ?? 'Code envoyé.',
      email: data['email'] as String? ?? email.trim().toLowerCase(),
      devCode: data['devCode'] as String?,
    );
  }

  Future<({String message, String registrationToken})> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    final response = await _api.client.post(
      '/auth/verify-registration-otp',
      data: {
        'email': email.trim().toLowerCase(),
        'code': code,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (
      message: data['message'] as String? ?? 'E-mail validé.',
      registrationToken: data['registrationToken'] as String,
    );
  }

  Future<UserModel> completeRegistration({
    required String email,
    required String registrationToken,
    required String name,
    required String password,
    String? phone,
  }) async {
    final response = await _api.client.post(
      '/auth/complete-registration',
      data: {
        'email': email.trim().toLowerCase(),
        'registrationToken': registrationToken,
        'name': name.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    await _api.saveToken(response.data['accessToken'] as String);
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<String> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final response = await _api.client.post(
      '/auth/register',
      data: {'email': email, 'name': name, 'password': password},
    );
    return response.data['message'] as String? ??
        'Compte créé. Vérifiez votre e-mail.';
  }

  Future<void> resendVerification(String email) async {
    await _api.client.post(
      '/auth/resend-verification',
      data: {'email': email},
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.client.post(
      '/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
      },
    );
    await _api.saveToken(response.data['accessToken'] as String);
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> loginWithGoogle() async {
    if (!isGoogleSignInConfigured) {
      throw StateError('GOOGLE_NOT_CONFIGURED');
    }

    if (kIsWeb || !GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('GOOGLE_USE_WEB_BUTTON');
    }

    final account = await _authenticate(
      scopes: const ['email', 'profile', 'openid'],
    );
    return completeGoogleLogin(account);
  }

  /// Finalise la connexion après un compte Google (mobile ou événement web GIS).
  Future<UserModel> completeGoogleLogin(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('GOOGLE_NO_ID_TOKEN');
    }

    final response = await _api.client.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    await _api.saveToken(response.data['accessToken'] as String);
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel?> getCurrentUser() async {
    final response = await _api.client.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _api.clearToken();
    await logoutGoogleOnly();
  }

  /// Sign-out Google sans toucher au jeton API (déjà effacé).
  Future<void> logoutGoogleOnly() async {
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
