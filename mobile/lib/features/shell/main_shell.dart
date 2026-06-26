import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/unread_messages_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ad_banner.dart';
import '../chat/screens/conversations_screen.dart';
import '../favorites/screens/favorites_screen.dart';
import '../home/screens/home_screen.dart';
import '../profile/screens/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authStateProvider).value != null) {
      ref.read(authStateProvider.notifier).refreshUser();
    }
  }

  bool _showPublishTab(bool isLoggedIn) => isLoggedIn;

  int _screenIndex(int navIndex, bool showPublish) {
    if (!showPublish) return navIndex;
    if (navIndex <= 1) return navIndex;
    return navIndex - 1;
  }

  Future<void> _initServices() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final chat = ref.read(chatServiceProvider);
    await chat.connect();
    chat.onAnyNewMessage(() {
      if (mounted) ref.invalidate(conversationsProvider);
    });
    ref.invalidate(conversationsProvider);
  }

  Widget _badgeIcon(IconData icon, int count) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.accentRed,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isLoggedIn = user != null;
    final showPublish = _showPublishTab(isLoggedIn);
    final showAds = user == null || user.plan == 'FREE';
    final navIndex = ref.watch(shellTabIndexProvider);
    final screenIndex = _screenIndex(navIndex, showPublish);
    final strings = ref.watch(stringsProvider);
    final unreadCount = ref.watch(unreadMessagesCountProvider);

    ref.listen(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value != null;
      final nowLoggedIn = next.value != null;
      ref
          .read(shellTabIndexProvider.notifier)
          .onAuthChanged(wasLoggedIn: wasLoggedIn, isLoggedIn: nowLoggedIn);
      if (!wasLoggedIn && nowLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
      }
    });

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: strings.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_outline),
        selectedIcon: const Icon(Icons.favorite),
        label: strings.favorites,
      ),
      if (showPublish)
        NavigationDestination(
          icon: const Icon(Icons.add_circle_outline),
          selectedIcon: const Icon(Icons.add_circle),
          label: strings.publish,
        ),
      NavigationDestination(
        icon: _badgeIcon(Icons.chat_outlined, unreadCount),
        selectedIcon: _badgeIcon(Icons.chat, unreadCount),
        label: strings.messages,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: strings.profile,
      ),
    ];

    final safeNavIndex = navIndex.clamp(0, destinations.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: screenIndex.clamp(0, 3),
        children: [
          const HomeScreen(),
          const FavoritesScreen(),
          const ConversationsScreen(),
          ProfileScreen(key: ValueKey(user?.id ?? 'guest')),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBanner(showAds: showAds),
          NavigationBar(
            selectedIndex: safeNavIndex,
            onDestinationSelected: (i) {
              if (showPublish && i == 2) {
                context.push('/create-listing');
                return;
              }
              ref.read(shellTabIndexProvider.notifier).setIndex(i);
              final messagesIndex =
                  ref.read(shellTabIndexProvider.notifier).messagesTabIndex;
              if (i == messagesIndex && isLoggedIn) {
                ref.invalidate(conversationsProvider);
              }
            },
            destinations: destinations,
          ),
        ],
      ),
    );
  }
}
