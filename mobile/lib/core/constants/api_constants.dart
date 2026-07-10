class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  /// Client OAuth iOS (Console Google → application iOS).
  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// Client OAuth Web — Android + vérification backend (même ID que backend/.env).
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Base publique (sans /api) pour pages légales, etc.
  static String get publicBaseUrl =>
      baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static String get privacyPolicyUrl =>
      String.fromEnvironment(
        'PRIVACY_POLICY_URL',
        defaultValue: '$publicBaseUrl/legal/privacy.html',
      );

  static String get termsOfUseUrl =>
      String.fromEnvironment(
        'TERMS_URL',
        defaultValue: '$publicBaseUrl/legal/terms.html',
      );

  /// AdMob — IDs test Google par défaut ; passer les vrais en dart-define release.
  static const admobAndroidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );

  static const admobIosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
  );

  static const admobBannerUnitId = String.fromEnvironment(
    'ADMOB_BANNER_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
}
