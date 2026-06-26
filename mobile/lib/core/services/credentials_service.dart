import 'package:shared_preferences/shared_preferences.dart';

class CredentialsService {
  static const _rememberKey = 'remember_credentials';
  static const _emailKey = 'saved_email';
  static const _passwordKey = 'saved_password';
  static const _versionKey = 'credentials_version';
  static const _currentVersion = 2;

  /// Réinitialise les identifiants sauvegardés après une mise à jour.
  Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_versionKey) == _currentVersion) return;
    await clear();
    await prefs.setInt(_versionKey, _currentVersion);
  }

  Future<bool> shouldRemember() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? false;
  }

  Future<({String email, String password})?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberKey) ?? false)) return null;

    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    if (email == null || password == null) return null;

    return (email: email, password: password);
  }

  Future<void> save({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);

    if (remember) {
      await prefs.setString(_emailKey, email.trim().toLowerCase());
      await prefs.setString(_passwordKey, password.trim());
    } else {
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }
}
