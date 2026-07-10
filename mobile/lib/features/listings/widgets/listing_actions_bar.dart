import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/favorite_ids_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../auth/screens/login_screen.dart';
import '../../chat/screens/conversations_screen.dart';

class ListingActionsBar extends ConsumerWidget {
  const ListingActionsBar({
    super.key,
    required this.listingId,
    required this.sellerId,
    this.sellerPhone,
    this.compact = false,
  });

  final String listingId;
  final String sellerId;
  final String? sellerPhone;
  final bool compact;

  bool _isLoggedIn(WidgetRef ref) => ref.watch(authStateProvider).value != null;

  void _requireLogin(BuildContext context, AppStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.loginRequired)),
    );
    showLoginModal(context);
  }

  Future<void> _toggleFavorite(
    WidgetRef ref,
    BuildContext context,
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

  Future<void> _startChat(
    WidgetRef ref,
    BuildContext context,
    AppStrings strings,
  ) async {
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

  Future<void> _callSeller(BuildContext context, AppStrings strings) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final isFav = ref.watch(favoriteIdsProvider).contains(listingId);

    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: strings.call,
            onPressed: () => _callSeller(context, strings),
            icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
          ),
          IconButton(
            tooltip: isFav ? strings.removeFavorite : strings.addToFavorites,
            onPressed: () => _toggleFavorite(ref, context, strings),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.accentRed : AppColors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: strings.discussion,
            onPressed: () => _startChat(ref, context, strings),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callSeller(context, strings),
                icon: const Icon(Icons.phone),
                label: Text(strings.call),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryBlue),
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toggleFavorite(ref, context, strings),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.accentRed : null,
                ),
                label: Text(isFav ? strings.favorite : strings.favorites),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: isFav ? AppColors.accentRed : null,
                  side: isFav
                      ? const BorderSide(color: AppColors.accentRed)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startChat(ref, context, strings),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(strings.discussion),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
