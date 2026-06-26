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
import '../services/user_cache_service.dart';
import '../services/users_service.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/home/providers/listings_provider.dart';
import '../services/listings_bootstrap.dart';
import '../../features/listings/providers/my_listings_provider.dart';
import '../../features/subscriptions/providers/plans_provider.dart';
import 'server_config_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider).value ?? ApiConstants.baseUrl;
  return ApiService(baseUrl: baseUrl);
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

  Future<void> _persistUser(UserModel user) => _userCache.save(user);

  bool get _shouldSkipRemoteRefresh =>
      _skipRemoteRefreshUntil != null &&
      DateTime.now().isBefore(_skipRemoteRefreshUntil!);

  void _markProfileSavedLocally() {
    _skipRemoteRefreshUntil = DateTime.now().add(const Duration(seconds: 90));
  }

  Future<void> _clearStoredSession() async {
    await ref.read(authServiceProvider).logout();
    await _userCache.clear();
  }

  Future<UserModel?> _restoreSession() async {
    final token = await ref.read(apiServiceProvider).getToken();
    if (token == null) {
      await _userCache.clear();
      return null;
    }

    final cached = await _userCache.load();

    try {
      await ref.read(apiBaseUrlProvider.future);
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null) {
        await _clearStoredSession();
        return null;
      }
      if (cached != null && _isSameProfile(cached, user)) {
        return cached;
      }
      await _persistUser(user);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearStoredSession();
        return null;
      }
      return cached;
    } catch (_) {
      return cached;
    }
  }

  bool _isSameProfile(UserModel a, UserModel b) =>
      a.id == b.id &&
      a.name == b.name &&
      a.phone == b.phone &&
      a.avatarUrl == b.avatarUrl &&
      a.plan == b.plan &&
      a.isEmailVerified == b.isEmailVerified;

  @override
  Future<UserModel?> build() async {
    final auth = ref.read(authServiceProvider);
    try {
      await auth
          .initGoogle()
          .timeout(const Duration(seconds: 3), onTimeout: () {});
    } catch (_) {
      // Google Sign-In optionnel en développement local.
    }

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

    final previous = state.value ?? await _userCache.load();
    if (previous != null && state.value == null) {
      state = AsyncData(previous);
    }

    try {
      await ref.read(apiBaseUrlProvider.future);
      final user = await ref.read(authServiceProvider).getCurrentUser();
      if (user == null) {
        await _clearStoredSession();
        state = const AsyncData(null);
        return;
      }
      await _persistUser(user);
      state = AsyncData(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearStoredSession();
        state = const AsyncData(null);
        return;
      }
      if (previous != null) {
        state = AsyncData(previous);
      }
    } catch (_) {
      if (previous != null) {
        state = AsyncData(previous);
      }
    }
  }

  Future<void> logout() async {
    await _clearStoredSession();
    ref.read(chatServiceProvider).disconnect();
    await _resetUserScopedState();
    state = const AsyncData(null);
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
