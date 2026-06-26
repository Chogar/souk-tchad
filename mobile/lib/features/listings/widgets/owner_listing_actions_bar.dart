import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/delete_listing_helper.dart';

class OwnerListingActionsBar extends ConsumerWidget {
  const OwnerListingActionsBar({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  final String listingId;
  final String listingTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/edit-listing/$listingId'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(strings.edit),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryBlue),
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => deleteListingWithConfirmation(
                  context: context,
                  ref: ref,
                  listingId: listingId,
                  listingTitle: listingTitle,
                  onSuccess: () {
                    if (context.mounted) context.pop();
                  },
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.delete),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.accentRed),
                  foregroundColor: AppColors.accentRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
