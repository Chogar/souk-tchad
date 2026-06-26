import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_otp_screen.dart';
import '../../features/auth/screens/register_profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../models/conversation_model.dart';
import '../../features/shell/main_shell.dart';
import '../../features/listings/screens/create_listing_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/my_listings_screen.dart';
import '../../features/listings/screens/edit_listing_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.value;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location.startsWith('/register/');
      final isSplash = location == '/splash';

      bool requiresAuth(String path) {
        if (path == '/create-listing' ||
            path == '/my-listings' ||
            path == '/profile') {
          return true;
        }
        return path.startsWith('/edit-listing/') || path.startsWith('/chat/');
      }

      if (isSplash) return null;
      if (isLoading) return '/splash';

      if (user == null && requiresAuth(location)) {
        final target = state.uri.toString();
        return '/login?redirect=${Uri.encodeComponent(target)}';
      }

      if (user != null && isAuthRoute) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) return redirect;
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            builder: (context, state) => const RegisterOtpScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const RegisterProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final conversation = state.extra as ConversationModel?;
          return ChatScreen(
            conversationId: id,
            conversation: conversation,
          );
        },
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/create-listing',
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-listing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditListingScreen(listingId: id);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref ref;
}
