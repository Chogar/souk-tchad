import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/utils/api_error.dart';
import '../../home/providers/listings_provider.dart';
import '../providers/my_listings_provider.dart';

Future<bool> confirmDeleteListing(
  BuildContext context,
  AppStrings strings, {
  required String listingTitle,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          title: Text(strings.deleteListingTitle),
          content: Text(strings.deleteListingMessage(listingTitle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.delete),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> deleteListingWithConfirmation({
  required BuildContext context,
  required WidgetRef ref,
  required String listingId,
  required String listingTitle,
  VoidCallback? onSuccess,
}) async {
  final strings = ref.read(stringsProvider);
  final confirmed = await confirmDeleteListing(
    context,
    strings,
    listingTitle: listingTitle,
  );
  if (!confirmed || !context.mounted) return false;

  try {
    await ref.read(listingsServiceProvider).deleteListing(listingId);
    ref.invalidate(myListingsProvider);
    ref.invalidate(listingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.listingDeleted)),
      );
      onSuccess?.call();
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.deleteListingError(apiErrorMessage(e, strings)))),
      );
    }
    return false;
  }
}
