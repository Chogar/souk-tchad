import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

enum AppLocale { fr, ar, en }

class LocaleNotifier extends Notifier<AppLocale> {
  static const _key = 'app_locale';

  @override
  AppLocale build() {
    Future.microtask(_loadStored);
    return AppLocale.fr;
  }

  Future<void> _loadStored() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    final loaded = _fromCode(code);
    if (loaded != null && state != loaded) {
      state = loaded;
    }
  }

  AppLocale? _fromCode(String? code) {
    switch (code) {
      case 'ar':
        return AppLocale.ar;
      case 'en':
        return AppLocale.en;
      case 'fr':
        return AppLocale.fr;
      default:
        return null;
    }
  }

  String _toCode(AppLocale locale) {
    switch (locale) {
      case AppLocale.ar:
        return 'ar';
      case AppLocale.en:
        return 'en';
      case AppLocale.fr:
        return 'fr';
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toCode(locale));
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(localeProvider));
});
