import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../providers/plans_provider.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final user = ref.watch(authStateProvider).value;
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.subscriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: plansAsync.when(
        data: (plans) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(user.name[0])),
                  title: Text(user.name),
                  subtitle: Text(strings.currentPlanValue(user.plan)),
                ),
              ),
            const SizedBox(height: 16),
            ...plans.map((plan) {
              final isCurrent = user?.plan == plan.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            plan.price == 0
                                ? strings.free
                                : strings.pricePerMonthUsd(plan.price),
                            style: const TextStyle(
                              color: AppColors.accentRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.maxListings == -1
                            ? strings.unlimitedListings
                            : strings.activeListingsCount(plan.maxListings),
                      ),
                      if (plan.hasAds) Text(strings.containsAds),
                      const SizedBox(height: 12),
                      if (isCurrent)
                        Chip(label: Text(strings.current))
                      else
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final updated = await ref
                                  .read(subscriptionsServiceProvider)
                                  .subscribe(plan.id);
                              await ref
                                  .read(authStateProvider.notifier)
                                  .setUser(updated);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      strings.planActivated(plan.name),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      strings.errorWith(
                                        apiErrorMessage(e, strings),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(strings.choose),
                        ),
                    ],
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                strings.paymentNote,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(strings.errorWith(apiErrorMessage(e, strings))),
        ),
      ),
    );
  }
}
