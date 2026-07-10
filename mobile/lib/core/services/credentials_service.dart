import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise uniquement l'e-mail (jamais le mot de passe).
class CredentialsService {
  static const _rememberKey = 'remember_credentials';
  static const _emailKey = 'saved_email';
  static const _passwordKey = 'saved_password';
  static const _versionKey = 'credentials_version';
  static const _currentVersion = 3;

  /// Réinitialise les identifiants après une mise à jour (purge MDP en clair).
  Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_versionKey) == _currentVersion) {
      // Toujours supprimer un éventuel mot de passe résiduel.
      await prefs.remove(_passwordKey);
      return;
    }
    await prefs.remove(_passwordKey);
    await prefs.setInt(_versionKey, _currentVersion);
  }

  Future<bool> shouldRemember() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<({String email, String password})?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;

    final email = prefs.getString(_emailKey);
    if (email == null || email.isEmpty) return null;

    // Plus de mot de passe stocké — l'UI préremplit seulement l'e-mail.
    return (email: email, password: '');
  }

  Future<void> save({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    await prefs.remove(_passwordKey);

    if (remember) {
      await prefs.setString(_emailKey, email.trim().toLowerCase());
    } else {
      await prefs.remove(_emailKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }
}
