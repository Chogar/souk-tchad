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

  Future<void> initGoogle() async {
    final serverClientId = ApiConstants.googleServerClientId.isNotEmpty
        ? ApiConstants.googleServerClientId
        : ApiConstants.googleClientId;

    await _googleSignIn.initialize(
      clientId: ApiConstants.googleClientId.isNotEmpty
          ? ApiConstants.googleClientId
          : null,
      serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    );
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

  /// Récupère l'e-mail Gmail choisi sans créer de session.
  Future<String?> pickGoogleEmail() async {
    if (!isGoogleSignInConfigured) {
      throw StateError('GOOGLE_NOT_CONFIGURED');
    }

    await initGoogle();

    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );
      final email = account.email;
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      return email;
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

    await initGoogle();

    // Déconnecte pour afficher le sélecteur de tous les comptes Gmail du téléphone.
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }

    late final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
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

    final idToken = account.authentication.idToken;
    if (idToken == null) {
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
    try {
      await _googleSignIn.disconnect().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
