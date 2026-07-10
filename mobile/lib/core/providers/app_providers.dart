import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../constants/api_constants.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/chat_service.dart';
import '../services/favorites_service.dart';
import '../services/listings_service.dart';
import '../services/notifications_api_service.dart';
import '../services/push_notification_service.dart';
import '../services/credentials_service.dart';
import '../services/subscriptions_service.dart';
import '../services/admin_service.dart';
import '../services/user_cache_service.dart';
import '../services/users_service.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/home/providers/listings_provider.dart';
import '../services/listings_bootstrap.dart';
import '../../features/listings/providers/my_listings_provider.dart';
import '../../features/subscriptions/providers/plans_provider.dart';
import 'server_config_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  // Une seule instance : ne pas recréer à chaque tick de apiBaseUrlProvider
  // (sinon le jeton est réhydraté depuis le disque et annule le logout).
  final initial =
      ref.read(apiBaseUrlProvider).value ?? ApiConstants.baseUrl;
  final api = ApiService(baseUrl: initial);
  ref.listen<AsyncValue<String>>(apiBaseUrlProvider, (previous, next) {
    final url = next.value;
    if (url != null && url.isNotEmpty) {
      api.updateBaseUrl(url);
    }
  });
  return api;
});

final credentialsServiceProvider =
    Provider<CredentialsService>((ref) => CredentialsService());

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final userCacheServiceProvider =
    Provider<UserCacheService>((ref) => UserCacheService());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiServiceProvider)),
);

final listingsServiceProvider = Provider<ListingsService>(
  (ref) => ListingsService(ref.watch(apiServiceProvider)),
);

final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => FavoritesService(ref.watch(apiServiceProvider)),
);

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.watch(apiServiceProvider)),
);

final aiServiceProvider = Provider<AiService>(
  (ref) => AiService(ref.watch(apiServiceProvider)),
);

final subscriptionsServiceProvider = Provider<SubscriptionsService>(
  (ref) => SubscriptionsService(ref.watch(apiServiceProvider)),
);

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(ref.watch(apiServiceProvider)),
);

final usersServiceProvider = Provider<UsersService>(
  (ref) => UsersService(ref.watch(apiServiceProvider)),
);

final notificationsApiServiceProvider = Provider<NotificationsApiService>(
  (ref) => NotificationsApiService(ref.watch(apiServiceProvider)),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(
    (token, platform) => ref
        .read(notificationsApiServiceProvider)
        .registerToken(token, platform: platform),
  ),
);

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

final shellTabIndexProvider =
    NotifierProvider<ShellTabNotifier, int>(ShellTabNotifier.new);

class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  bool get _showPublishTab => ref.read(authStateProvider).value != null;

  /// Index onglet Messages (3 si connecté avec Publier, 2 sinon).
  int get messagesTabIndex => _showPublishTab ? 3 : 2;

  void setIndex(int index) => state = index;

  void goToMessages() => state = messagesTabIndex;

  /// Ajuste l'index quand l'utilisateur se connecte ou se déconnecte.
  void onAuthChanged({required bool wasLoggedIn, required bool isLoggedIn}) {
    if (wasLoggedIn == isLoggedIn) return;
    if (isLoggedIn) {
      if (state >= 2) state = state + 1;
      return;
    }
    if (state == 2) {
      state = 0;
    } else if (state > 2) {
      state = state - 1;
    }
  }
}

class AuthNotifier extends AsyncNotifier<UserModel?> {
  UserCacheService get _userCache => ref.read(userCacheServiceProvider);
  DateTime? _skipRemoteRefreshUntil;
  /// Incrémenté à chaque logout pour annuler les refresh en cours.
  int _sessionEpoch = 0;

  Future<void> _persistUser(UserModel user) => _userCache.save(user);

  bool get _shouldSkipRemoteRefresh =>
      _skipRemoteRefreshUntil != null &&
      DateTime.now().isBefore(_skipRemoteRefreshUntil!);

  void _markProfileSavedLocally() {
    _skipRemoteRefreshUntil = DateTime.now().add(const Duration(seconds: 90));
  }

  Future<void> _clearStoredSession() async {
    await ref.read(apiServiceProvider).clearToken();
    await _userCache.clear();
    try {
      await ref.read(authServiceProvider).logoutGoogleOnly();
    } catch (_) {}
  }

  Future<UserModel?> _restoreSession() async {
    final token = await ref.read(apiServiceProvider).getToken();
    if (token == null) {
      await _userCache.clear();
      return null;
    }

    final cached = await _userCache.load();
    // Afficher tout de suite le cache, puis rafraîchir en arrière-plan.
    if (cached != null) {
      unawaited(_refreshSessionInBackground());
      return cached;
    }

    try {
      await ref
          .read(apiBaseUrlProvider.future)
          .timeout(const Duration(seconds: 2));
      final user = await ref
          .read(authServiceProvider)
          .getCurrentUser()
          .timeout(const Duration(seconds: 3));
      if (user == null) {
        await _clearStoredSession();
        return null;
      }
      await _persistUser(user);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearStoredSession();
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshSessionInBackground() async {
    final epoch = _sessionEpoch;
    try {
      await ref.read(apiBaseUrlProvider.future);
      final token = await ref.read(apiServiceProvider).getToken();
      if (token == null || epoch != _sessionEpoch) return;

      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (epoch != _sessionEpoch) return;
      if (user == null) {
        await _clearStoredSession();
        if (epoch == _sessionEpoch) state = const AsyncData(null);
        return;
      }
      await _persistUser(user);
      if (epoch == _sessionEpoch && state.value?.id == user.id) {
        state = AsyncData(user);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && epoch == _sessionEpoch) {
        await _clearStoredSession();
        state = const AsyncData(null);
      }
    } catch (_) {}
  }

  @override
  Future<UserModel?> build() async {
    // Google Sign-In : ne jamais bloquer le démarrage.
    unawaited(() async {
      try {
        await ref
            .read(authServiceProvider)
            .initGoogle()
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      } catch (_) {}
    }());

    return _restoreSession();
  }

  Future<void> _resetUserScopedState() async {
    await ref.read(cacheServiceProvider).clearUserData();
    ref.invalidate(myListingsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(plansProvider);
    ref.read(shellTabIndexProvider.notifier).setIndex(0);
  }

  Future<void> _refreshCatalog() => refreshListingsCatalog(ref);

  Future<void> login(
    String email,
    String password, {
    bool remember = false,
  }) async {
    await _resetUserScopedState();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authServiceProvider);
      final user = await auth.login(email: email, password: password);
      await _persistUser(user);
      await ref.read(credentialsServiceProvider).save(
            email: email,
            password: password,
            remember: remember,
          );
      await ref.read(pushNotificationServiceProvider).enableAfterLogin();
      await _refreshCatalog();
      return user;
    });
  }

  Future<String> register(String email, String name, String password) async {
    final auth = ref.read(authServiceProvider);
    return auth.register(email: email, name: name, password: password);
  }

  Future<({String message, String? devCode})> sendRegistrationOtp(
    String email,
  ) async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.sendRegistrationOtp(email);
    return (message: result.message, devCode: result.devCode);
  }

  Future<String> verifyRegistrationOtp(String email, String code) async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.verifyRegistrationOtp(email: email, code: code);
    return result.registrationToken;
  }

  Future<void> completeRegistration({
    required String email,
    required String registrationToken,
    required String name,
    required String password,
    String? phone,
  }) async {
    await _resetUserScopedState();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authServiceProvider);
      final user = await auth.completeRegistration(
        email: email,
        registrationToken: registrationToken,
        name: name,
        password: password,
        phone: phone,
      );
      await _persistUser(user);
      await ref.read(pushNotificationServiceProvider).enableAfterLogin();
      await _refreshCatalog();
      return user;
    });
  }

  Future<void> loginWithGoogle() async {
    await _resetUserScopedState();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authServiceProvider);
      final user = await auth.loginWithGoogle();
      await _persistUser(user);
      await ref.read(pushNotificationServiceProvider).enableAfterLogin();
      await _refreshCatalog();
      return user;
    });
  }

  Future<void> setUser(UserModel user) async {
    state = AsyncData(user);
    await _persistUser(user);
    _markProfileSavedLocally();
  }

  Future<void> refreshUser({bool force = false}) async {
    if (!force && _shouldSkipRemoteRefresh) return;

    final epoch = _sessionEpoch;
    final token = await ref.read(apiServiceProvider).getToken();
    if (token == null) {
      if (epoch == _sessionEpoch) state = const AsyncData(null);
      return;
    }

    final previous = state.value;

    try {
      await ref.read(apiBaseUrlProvider.future);
      if (epoch != _sessionEpoch) return;

      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (epoch != _sessionEpoch) return;

      if (user == null) {
        await _clearStoredSession();
        if (epoch == _sessionEpoch) state = const AsyncData(null);
        return;
      }
      await _persistUser(user);
      if (epoch == _sessionEpoch) state = AsyncData(user);
    } on DioException catch (e) {
      if (epoch != _sessionEpoch) return;
      if (e.response?.statusCode == 401) {
        await _clearStoredSession();
        state = const AsyncData(null);
        return;
      }
      // Ne jamais réinjecter un user si on est déjà déconnecté.
      if (previous != null && state.value != null) {
        state = AsyncData(previous);
      }
    } catch (_) {
      if (epoch != _sessionEpoch) return;
      if (previous != null && state.value != null) {
        state = AsyncData(previous);
      }
    }
  }

  Future<void> logout() async {
    _sessionEpoch++;
    _skipRemoteRefreshUntil = null;

    final api = ref.read(apiServiceProvider);
    // Immédiat : couper l'UI sans attendre le disque (sinon le bouton paraît mort).
    api.invalidateSession();
    state = const AsyncData(null);
    ref.read(shellTabIndexProvider.notifier).setIndex(0);

    try {
      ref.read(chatServiceProvider).disconnect();
    } catch (_) {}

    // Disque / Google en arrière-plan (_blockDiskHydration empêche toute restauration).
    unawaited(() async {
      try {
        await api.clearToken();
      } catch (_) {}
      try {
        await _userCache.clear();
      } catch (_) {}
      try {
        await ref.read(authServiceProvider).logoutGoogleOnly();
      } catch (_) {}
      try {
        await ref.read(cacheServiceProvider).clearUserData();
      } catch (_) {}
      ref.invalidate(myListingsProvider);
      ref.invalidate(conversationsProvider);
      ref.invalidate(plansProvider);
    }());
  }

  Future<void> deleteAccount() async {
    await ref.read(usersServiceProvider).deleteAccount();
    await logout();
  }
}

/// Charge annonces + catégories depuis l'API, met à jour le cache, rafraîchit l'UI.
Future<void> refreshListingsCatalog(dynamic ref) async {
  await ref.read(apiBaseUrlProvider.future);

  final service = ref.read(listingsServiceProvider) as ListingsService;
  final cache = ref.read(cacheServiceProvider) as CacheService;

  try {
    final listings = await service.getListings();
    final unique = <String, ListingModel>{};
    for (final listing in listings) {
      unique[listing.id] = listing;
    }
    final deduped = unique.values.toList();

    if (deduped.isNotEmpty) {
      ListingsBootstrap.updateListings(deduped);
      await cache.cacheListings(
        deduped.map(listingToCacheJson).toList(),
      );
    }

    final categories = await service.getCategories();
    if (categories.isNotEmpty) {
      ListingsBootstrap.updateCategories(categories);
      try {
        await cache.cacheCategories(CategoryModel.toCacheJsonList(categories));
      } catch (_) {}
    }
  } catch (_) {}

  bumpCatalogVersion(ref);
}
