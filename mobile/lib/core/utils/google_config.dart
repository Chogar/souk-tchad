import '../constants/api_constants.dart';

/// Vérifie qu'un Client ID Google OAuth est réel (pas un placeholder).
bool isValidGoogleClientId(String id) {
  if (id.isEmpty) return false;
  if (!id.endsWith('.apps.googleusercontent.com')) return false;
  final lower = id.toLowerCase();
  return !lower.contains('your-') &&
      !lower.contains('votre-id') &&
      !lower.contains('example');
}

bool get isGoogleSignInConfigured =>
    isValidGoogleClientId(ApiConstants.googleClientId) &&
    isValidGoogleClientId(ApiConstants.googleServerClientId);
