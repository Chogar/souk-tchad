import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/cache_service.dart';
import 'core/services/listings_bootstrap.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = CacheService();
  // Ne pas bloquer le 1er frame : warm cache en arrière-plan.
  unawaited(ListingsBootstrap.warm(cache));
  runApp(const ProviderScope(child: SoukTchadApp()));
  _initAdsInBackground();
}

Future<void> _initAdsInBackground() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android)) {
    return;
  }
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 5));
  } catch (_) {
    // AdMob optionnel — ne pas bloquer le démarrage.
  }
}

class SoukTchadApp extends ConsumerWidget {
  const SoukTchadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themePref = ref.watch(themeModeProvider);
    final themeMode = themePref == AppThemePreference.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return MaterialApp.router(
      title: 'Souk Tchad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: switch (locale) {
        AppLocale.ar => const Locale('ar'),
        AppLocale.en => const Locale('en'),
        AppLocale.fr => const Locale('fr'),
      },
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => child ?? const SizedBox(),
      routerConfig: router,
    );
  }
}
