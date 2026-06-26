import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/favorite_ids_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_required_view.dart';
import '../../listings/widgets/listing_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final favoritesAsync = ref.watch(favoritesProvider);
    final api = ref.watch(apiServiceProvider);
    final strings = ref.watch(stringsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.myFavorites)),
        body: AuthRequiredView(
          icon: Icons.favorite_border,
          title: strings.guestFavoritesTitle,
          message: strings.guestFavoritesHint,
          redirectPath: '/',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.myFavorites),
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.noFavorites,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.noFavoritesHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(shellTabIndexProvider.notifier).setIndex(0),
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(strings.browseListings),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(favoritesProvider);
              await ref.read(favoriteIdsProvider.notifier).load();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      strings.favoriteCount(favorites.length),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final listing = favorites[i];
                        return Dismissible(
                          key: ValueKey(listing.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            try {
                              await ref
                                  .read(favoriteIdsProvider.notifier)
                                  .toggle(listing.id);
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.errorWith('$e')),
                                  ),
                                );
                              }
                              return false;
                            }
                          },
                          child: ListingCard(
                            listing: listing,
                            api: api,
                            layout: ListingCardLayout.grid,
                          ),
                        );
                      },
                      childCount: favorites.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(strings.errorWith('$e'))),
      ),
    );
  }
}
