import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/subscriptions_service.dart';

final plansProvider = FutureProvider<List<PlanModel>>((ref) async {
  return ref.read(subscriptionsServiceProvider).getPlans();
});
