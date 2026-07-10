import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'listing_photo.dart';

class MyListingTile extends StatelessWidget {
  const MyListingTile({
    super.key,
    required this.listing,
    required this.api,
    required this.strings,
    this.onEdit,
    this.onDelete,
  });

  final ListingModel listing;
  final ApiService api;
  final AppStrings strings;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.images.isNotEmpty
        ? api.mediaUrl(listing.images.first)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: ListingPhoto(
                    url: imageUrl,
                    error: _placeholder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormat.format(listing.price, strings.locale),
                      style: const TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (listing.status != 'ACTIVE')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Chip(
                          label: Text(
                            listing.status == 'MODERATED'
                                ? 'Masquée — modération'
                                : listing.status,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.orange.shade100,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    Text(
                      '${listing.category.icon} ${listing.city}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (onDelete != null)
                            TextButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.accentRed,
                              ),
                              label: Text(
                                strings.delete,
                                style: const TextStyle(
                                  color: AppColors.accentRed,
                                ),
                              ),
                            ),
                          if (onEdit != null)
                            TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(strings.edit),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
