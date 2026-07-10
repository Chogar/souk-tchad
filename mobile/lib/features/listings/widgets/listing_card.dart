import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/favorite_ids_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/currency_format.dart';
import '../../auth/screens/login_screen.dart';
import '../../chat/screens/conversations_screen.dart';
import 'listing_photo.dart';

enum ListingCardLayout { grid, list }

class ListingCard extends ConsumerWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.api,
    this.layout = ListingCardLayout.grid,
    this.showActions = true,
  });

  final ListingModel listing;
  final ApiService api;
  final ListingCardLayout layout;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (layout == ListingCardLayout.grid) {
      return _GridListingCard(
        listing: listing,
        api: api,
        showActions: showActions,
      );
    }
    return _ListListingCard(
      listing: listing,
      api: api,
      showActions: showActions,
    );
  }
}

class _GridListingCard extends ConsumerWidget {
  const _GridListingCard({
    required this.listing,
    required this.api,
    required this.showActions,
  });

  final ListingModel listing;
  final ApiService api;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final imageUrl = listing.images.isNotEmpty
        ? api.mediaUrl(listing.images.first)
        : null;
    final isFav = ref.watch(favoriteIdsProvider).contains(listing.id);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 13,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingPhoto(
                    url: imageUrl,
                    error: _placeholder(compact: true),
                  ),
                  if (showActions)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _ListingCardActions.toggleFavorite(
                            ref,
                            context,
                            listing.id,
                            strings,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isFav
                                  ? AppColors.accentRed
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.25,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormat.format(listing.price, strings.locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      listing.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 12,
                          color: AppColors.primaryBlue.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListListingCard extends ConsumerWidget {
  const _ListListingCard({
    required this.listing,
    required this.api,
    required this.showActions,
  });

  final ListingModel listing;
  final ApiService api;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final imageUrl = listing.images.isNotEmpty
        ? api.mediaUrl(listing.images.first)
        : null;
    final isFav = ref.watch(favoriteIdsProvider).contains(listing.id);

    return Material(
      color: Theme.of(context).cardColor,
      elevation: 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingPhoto(
                    url: imageUrl,
                    error: _placeholder(),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _CategoryBadge(icon: listing.category.icon),
                  ),
                  if (listing.images.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _PhotoCountBadge(count: listing.images.length),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormat.format(listing.price, strings.locale),
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.city} • ${listing.user.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (showActions)
              _ListActionsBar(
                listingId: listing.id,
                sellerId: listing.user.id,
                sellerPhone: listing.user.phone,
                isFav: isFav,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '1/$count',
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }
}

class _ListActionsBar extends ConsumerWidget {
  const _ListActionsBar({
    required this.listingId,
    required this.sellerId,
    required this.sellerPhone,
    required this.isFav,
  });

  final String listingId;
  final String sellerId;
  final String? sellerPhone;
  final bool isFav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: strings.call,
              onPressed: () => _ListingCardActions.callSeller(
                context,
                sellerPhone,
                strings,
              ),
              icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
            ),
            IconButton(
              tooltip:
                  isFav ? strings.removeFavorite : strings.addToFavorites,
              onPressed: () => _ListingCardActions.toggleFavorite(
                ref,
                context,
                listingId,
                strings,
              ),
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.accentRed : AppColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: strings.discussion,
              onPressed: () => _ListingCardActions.startChat(
                ref,
                context,
                listingId: listingId,
                sellerId: sellerId,
                strings: strings,
              ),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCardActions {
  static bool _isLoggedIn(WidgetRef ref) =>
      ref.watch(authStateProvider).value != null;

  static void _requireLogin(BuildContext context, AppStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.loginRequired)),
    );
    showLoginModal(context);
  }

  static Future<void> toggleFavorite(
    WidgetRef ref,
    BuildContext context,
    String listingId,
    AppStrings strings,
  ) async {
    if (!_isLoggedIn(ref)) {
      _requireLogin(context, strings);
      return;
    }

    try {
      await ref.read(favoriteIdsProvider.notifier).toggle(listingId);
      if (context.mounted) {
        final isFav = ref.read(favoriteIdsProvider).contains(listingId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFav ? strings.addedToFavorites : strings.removedFromFavorites,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, strings))),
        );
      }
    }
  }

  static Future<void> startChat(
    WidgetRef ref,
    BuildContext context, {
    required String listingId,
    required String sellerId,
    required AppStrings strings,
  }) async {
    if (!_isLoggedIn(ref)) {
      _requireLogin(context, strings);
      return;
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser?.id == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.ownListingHint)),
      );
      ref.read(shellTabIndexProvider.notifier).goToMessages();
      return;
    }

    try {
      final conv =
          await ref.read(chatServiceProvider).startConversation(listingId);
      ref.invalidate(conversationsProvider);
      ref.read(shellTabIndexProvider.notifier).goToMessages();
      if (context.mounted) {
        context.push('/chat/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, strings))),
        );
      }
    }
  }

  static Future<void> callSeller(
    BuildContext context,
    String? sellerPhone,
    AppStrings strings,
  ) async {
    final phone = sellerPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.noPhoneUseChat)),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.cannotCall)),
        );
      }
    }
  }
}

Widget _placeholder({bool compact = false}) {
  return Container(
    color: Colors.grey.shade200,
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: compact ? 28 : 48,
        color: Colors.grey,
      ),
    ),
  );
}
