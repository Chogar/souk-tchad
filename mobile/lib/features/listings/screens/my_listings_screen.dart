import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/utils/api_error.dart';
import '../providers/my_listings_provider.dart';
import '../utils/delete_listing_helper.dart';
import '../widgets/my_listing_tile.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);
    final api = ref.watch(apiServiceProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.myListings)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-listing'),
        child: const Icon(Icons.add),
      ),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(strings.noMyListingsYet),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-listing'),
                    icon: const Icon(Icons.add),
                    label: Text(strings.createListing),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myListingsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return MyListingTile(
                  listing: listing,
                  api: api,
                  strings: strings,
                  onEdit: () => context.push('/edit-listing/${listing.id}'),
                  onDelete: () => deleteListingWithConfirmation(
                    context: context,
                    ref: ref,
                    listingId: listing.id,
                    listingTitle: listing.title,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(strings.errorWith(apiErrorMessage(e, strings)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(myListingsProvider),
                  child: Text(strings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
