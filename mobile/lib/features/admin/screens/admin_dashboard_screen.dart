import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/currency_format.dart';
import '../widgets/admin_nav_bar.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminServiceProvider).getStats();
});

final adminPaymentsProvider =
    FutureProvider.autoDispose.family<List<AdminPaymentOrder>, String>((
      ref,
      status,
    ) {
      return ref
          .watch(adminServiceProvider)
          .getPayments(status: status.isEmpty ? null : status);
    });

final adminListingsProvider =
    FutureProvider.autoDispose.family<List<AdminListingRow>, String>((
      ref,
      status,
    ) {
      return ref
          .watch(adminServiceProvider)
          .getListings(status: status.isEmpty ? null : status);
    });

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _paymentFilter = 'PENDING';
  String _listingFilter = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(adminPaymentsProvider(_paymentFilter));
    ref.invalidate(adminListingsProvider(_listingFilter));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: adminSubPageAppBar(
          context: context,
          strings: ref.watch(stringsProvider),
          title: 'Administration',
        ),
        bottomNavigationBar: AdminBottomNavBar(
          strings: ref.watch(stringsProvider),
        ),
        body: const _AccessDenied(),
      );
    }

    final pendingCount =
        ref.watch(adminStatsProvider).asData?.value.paymentsPending ?? 0;
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: AdminBottomNavBar(strings: strings),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 148,
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: AdminNavIconButtons.leading(context, strings),
              actions: [
                IconButton(
                  tooltip: strings.adminPaymentSettingsTitle,
                  onPressed: () => context.push('/admin/payment-settings'),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                IconButton(
                  tooltip: strings.home,
                  onPressed: () => adminGoHome(context),
                  icon: const Icon(Icons.home_rounded),
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _AdminHero(adminName: user.name),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: AppColors.primaryBlue,
                  child: TabBar(
                    controller: _tabs,
                    indicatorColor: AppColors.accentGold,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.insights_rounded, size: 20),
                        text: 'Vue d’ensemble',
                      ),
                      Tab(
                        icon: Badge(
                          isLabelVisible: pendingCount > 0,
                          backgroundColor: AppColors.accentRed,
                          label: Text('$pendingCount'),
                          child: const Icon(
                            Icons.payments_outlined,
                            size: 20,
                          ),
                        ),
                        text: 'Paiements',
                      ),
                      const Tab(
                        icon: Icon(Icons.storefront_outlined, size: 20),
                        text: 'Annonces',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabs,
          children: [
            const _StatsTab(),
            _PaymentsTab(
              filter: _paymentFilter,
              onFilterChanged: (value) => setState(() => _paymentFilter = value),
              onChanged: _refresh,
            ),
            _ListingsTab(
              filter: _listingFilter,
              onFilterChanged: (value) => setState(() => _listingFilter = value),
              onChanged: _refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.adminName});

  final String adminName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001A44),
            AppColors.primaryBlue,
            Color(0xFF0A3A7A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 16, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AppColors.accentGold,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Espace administrateur',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bonjour, $adminName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stats, paiements et modération',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppColors.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Accès réservé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Seuls les administrateurs peuvent ouvrir cet espace.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

Future<void> _adminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
  required dynamic strings,
  bool isDestructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                isDestructive ? AppColors.accentRed : AppColors.primaryBlue,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await onConfirm();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, strings))),
      );
    }
  }
}

Future<void> _confirmPaymentAction({
  required BuildContext context,
  required WidgetRef ref,
  required AdminPaymentOrder order,
  required dynamic strings,
  required Future<void> Function() onChanged,
}) {
  return _adminConfirmDialog(
    context: context,
    title: 'Confirmer le paiement ?',
    message:
        'Le plan ${order.plan} sera activé pour ${order.userName ?? 'cet utilisateur'}.',
    confirmLabel: 'Confirmer',
    strings: strings,
    onConfirm: () async {
      await ref.read(adminServiceProvider).confirmPayment(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement confirmé, plan activé.')),
        );
      }
      await onChanged();
    },
  );
}

Future<void> _confirmRejectAction({
  required BuildContext context,
  required WidgetRef ref,
  required AdminPaymentOrder order,
  required dynamic strings,
  required Future<void> Function() onChanged,
}) {
  return _adminConfirmDialog(
    context: context,
    title: 'Refuser ce paiement ?',
    message: 'Le paiement sera marqué comme refusé.',
    confirmLabel: 'Refuser',
    isDestructive: true,
    strings: strings,
    onConfirm: () async {
      await ref.read(adminServiceProvider).rejectPayment(order.id);
      await onChanged();
    },
  );
}

class _PaymentOrderCard extends StatelessWidget {
  const _PaymentOrderCard({
    required this.order,
    required this.dateFmt,
    required this.strings,
    required this.compact,
    required this.onShowDetails,
    required this.onConfirm,
    required this.onReject,
  });

  final AdminPaymentOrder order;
  final DateFormat dateFmt;
  final dynamic strings;
  final bool compact;
  final VoidCallback onShowDetails;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == 'PENDING';

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 18 : 22,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  _initials(order.userName),
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName ?? 'Utilisateur',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 13 : 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.userEmail ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 8 : 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetaItem(label: 'Plan', value: order.plan),
                      const SizedBox(height: 6),
                      _MetaItem(
                        label: 'Montant',
                        value: CurrencyFormat.format(
                          order.amount.toDouble(),
                          strings.locale,
                        ),
                        valueColor: AppColors.accentRed,
                      ),
                      const SizedBox(height: 6),
                      _MetaItem(
                        label: 'Date',
                        value: dateFmt.format(order.createdAt.toLocal()),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _MetaItem(label: 'Plan', value: order.plan),
                      ),
                      Expanded(
                        child: _MetaItem(
                          label: 'Montant',
                          value: CurrencyFormat.format(
                            order.amount.toDouble(),
                            strings.locale,
                          ),
                          valueColor: AppColors.accentRed,
                        ),
                      ),
                      Expanded(
                        child: _MetaItem(
                          label: 'Date',
                          value: dateFmt.format(order.createdAt.toLocal()),
                        ),
                      ),
                    ],
                  ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShowDetails,
              icon: Icon(Icons.visibility_outlined, size: compact ? 16 : 18),
              label: Text(compact ? 'Détails' : 'Voir les détails'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                visualDensity:
                    compact ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(compact ? 'Refuser' : 'Refuser'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(compact ? 'OK' : 'Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStatsProvider);
    final strings = ref.watch(stringsProvider);

    return async.when(
      loading: () => const _LoadingState(),
      error: (e, _) => _ErrorState(
        message: apiErrorMessage(e, strings),
        onRetry: () => ref.invalidate(adminStatsProvider),
      ),
      data: (stats) {
        final planTotal = stats.usersByPlan.values.fold<int>(
          0,
          (a, b) => a + b,
        );

        return RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async => ref.invalidate(adminStatsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 900
                      ? 4
                      : width >= 560
                          ? 3
                          : 2;
                  final itemWidth =
                      (width - (12 * (crossAxisCount - 1))) / crossAxisCount;

                  final cards = [
                    _StatCard(
                      width: itemWidth,
                      label: 'Utilisateurs',
                      value: '${stats.usersTotal}',
                      subtitle: '${stats.usersVerified} vérifiés',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    _StatCard(
                      width: itemWidth,
                      label: 'Annonces actives',
                      value: '${stats.listingsActive}',
                      subtitle: '${stats.listingsTotal} au total',
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF0F766E),
                    ),
                    _StatCard(
                      width: itemWidth,
                      label: 'À confirmer',
                      value: '${stats.paymentsPending}',
                      subtitle: '${stats.paymentsPaid} déjà payés',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFB45309),
                      highlight: stats.paymentsPending > 0,
                    ),
                    _StatCard(
                      width: itemWidth,
                      label: 'Revenus',
                      value: CurrencyFormat.format(
                        stats.revenueXaf.toDouble(),
                        strings.locale,
                      ),
                      subtitle: 'Abonnements confirmés',
                      icon: Icons.payments_rounded,
                      color: AppColors.accentRed,
                    ),
                    _StatCard(
                      width: itemWidth,
                      label: 'Conversations',
                      value: '${stats.conversations}',
                      subtitle: '${stats.messages} messages',
                      icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF1D4ED8),
                    ),
                    _StatCard(
                      width: itemWidth,
                      label: 'Modérées',
                      value: '${stats.listingsModerated}',
                      subtitle: 'Annonces en revue',
                      icon: Icons.gavel_rounded,
                      color: const Color(0xFF7C2D12),
                    ),
                  ];

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 22),
              _SectionCard(
                title: 'Répartition des plans',
                subtitle: 'Abonnements actifs par formule',
                child: planTotal == 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Aucune donnée de plan pour le moment.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : Column(
                        children: stats.usersByPlan.entries.map((e) {
                          final ratio = e.value / planTotal;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _PlanBar(
                              label: _planLabel(e.key),
                              count: e.value,
                              ratio: ratio,
                              color: _planColor(e.key),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _planLabel(String key) {
    switch (key.toUpperCase()) {
      case 'FREE':
        return 'Gratuit';
      case 'BASIC':
        return 'Basique';
      case 'PRO':
      case 'PROFESSIONAL':
        return 'Professionnel';
      case 'BUSINESS':
        return 'Business';
      default:
        return key;
    }
  }

  Color _planColor(String key) {
    switch (key.toUpperCase()) {
      case 'FREE':
        return Colors.blueGrey;
      case 'BASIC':
        return const Color(0xFF2563EB);
      case 'PRO':
      case 'PROFESSIONAL':
        return AppColors.accentGold;
      case 'BUSINESS':
        return AppColors.accentRed;
      default:
        return AppColors.primaryBlue;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final double width;
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight
                ? color.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: highlight ? 0.14 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Action',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PlanBar extends StatelessWidget {
  const _PlanBar({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int count;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${(ratio * 100).round()}%)',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({
    required this.filter,
    required this.onFilterChanged,
    required this.onChanged,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPaymentsProvider(filter));
    final strings = ref.watch(stringsProvider);
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'En attente',
                  selected: filter == 'PENDING',
                  onTap: () => onFilterChanged('PENDING'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Confirmés',
                  selected: filter == 'PAID',
                  onTap: () => onFilterChanged('PAID'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Refusés',
                  selected: filter == 'CANCELLED',
                  onTap: () => onFilterChanged('CANCELLED'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tous',
                  selected: filter.isEmpty,
                  onTap: () => onFilterChanged(''),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const _LoadingState(),
            error: (e, _) => _ErrorState(
              message: apiErrorMessage(e, strings),
              onRetry: () => ref.invalidate(adminPaymentsProvider(filter)),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return _EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Aucun paiement',
                  subtitle: filter == 'PENDING'
                      ? 'Tout est à jour — aucun paiement en attente.'
                      : 'Aucun résultat pour ce filtre.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = MediaQuery.sizeOf(context);
                  final crossAxisCount =
                      AppBreakpoints.adminPaymentsCrossAxisCount(size);
                  final aspectRatio =
                      AppBreakpoints.adminPaymentsChildAspectRatio(size);

                  return RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: () async =>
                        ref.invalidate(adminPaymentsProvider(filter)),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _PaymentOrderCard(
                          order: orders[index],
                          dateFmt: dateFmt,
                          strings: strings,
                          compact: true,
                          onShowDetails: () => _showPaymentDetails(
                            context: context,
                            ref: ref,
                            order: orders[index],
                            dateFmt: dateFmt,
                            strings: strings,
                            onChanged: onChanged,
                          ),
                          onConfirm: () => _confirmPaymentAction(
                            context: context,
                            ref: ref,
                            order: orders[index],
                            strings: strings,
                            onChanged: onChanged,
                          ),
                          onReject: () => _confirmRejectAction(
                            context: context,
                            ref: ref,
                            order: orders[index],
                            strings: strings,
                            onChanged: onChanged,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showPaymentDetails({
    required BuildContext context,
    required WidgetRef ref,
    required AdminPaymentOrder order,
    required DateFormat dateFmt,
    required dynamic strings,
    required Future<void> Function() onChanged,
  }) {
    final api = ref.read(apiServiceProvider);
    final proofUrl = order.proofImageUrl != null &&
            order.proofImageUrl!.isNotEmpty
        ? api.mediaUrl(order.proofImageUrl!)
        : null;
    final isPending = order.status == 'PENDING';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.58,
      ),
      builder: (ctx) {
        final sheetWidth = MediaQuery.sizeOf(ctx).width;
        final contentMaxWidth = sheetWidth >= 520 ? 440.0 : sheetWidth;

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 10,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Détails du paiement',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _CompactDetail(
                            label: 'Client',
                            value: order.userName ?? 'Utilisateur',
                          ),
                          _CompactDetail(
                            label: 'Plan',
                            value: order.plan,
                          ),
                          _CompactDetail(
                            label: 'Montant',
                            value: CurrencyFormat.format(
                              order.amount.toDouble(),
                              strings.locale,
                            ),
                            valueColor: AppColors.accentRed,
                          ),
                          _CompactDetail(
                            label: 'Opérateur',
                            value: order.providerLabel,
                          ),
                          _CompactDetail(
                            label: 'Mobile Money',
                            value: order.payerReference ?? '—',
                          ),
                          _CompactDetail(
                            label: 'Date',
                            value: dateFmt.format(order.createdAt.toLocal()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _CompactDetail(
                        label: 'E-mail',
                        value: order.userEmail ?? '—',
                        fullWidth: true,
                      ),
                      if (order.userPhone != null &&
                          order.userPhone!.isNotEmpty)
                        _CompactDetail(
                          label: 'Téléphone',
                          value: order.userPhone!,
                          fullWidth: true,
                        ),
                      _CompactDetail(
                        label: 'Réf.',
                        value: order.id,
                        fullWidth: true,
                        selectable: true,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preuve',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (proofUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: Image.network(
                              proofUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 80,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Image indisponible',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Aucune capture fournie.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _confirmRejectAction(
                                    context: context,
                                    ref: ref,
                                    order: order,
                                    strings: strings,
                                    onChanged: onChanged,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accentRed,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Refuser'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _confirmPaymentAction(
                                    context: context,
                                    ref: ref,
                                    order: order,
                                    strings: strings,
                                    onChanged: onChanged,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Confirmer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactDetail extends StatelessWidget {
  const _CompactDetail({
    required this.label,
    required this.value,
    this.valueColor,
    this.fullWidth = false,
    this.selectable = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool fullWidth;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 1),
        selectable
            ? SelectableText(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: valueColor ?? Colors.black87,
                ),
              )
            : Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: valueColor ?? Colors.black87,
                ),
              ),
      ],
    );

    if (fullWidth) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: content,
      );
    }

    return SizedBox(
      width: 130,
      child: content,
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab({
    required this.filter,
    required this.onFilterChanged,
    required this.onChanged,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminListingsProvider(filter));
    final strings = ref.watch(stringsProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Toutes',
                  selected: filter.isEmpty,
                  onTap: () => onFilterChanged(''),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Actives',
                  selected: filter == 'ACTIVE',
                  onTap: () => onFilterChanged('ACTIVE'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Modérées',
                  selected: filter == 'MODERATED',
                  onTap: () => onFilterChanged('MODERATED'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Vendues',
                  selected: filter == 'SOLD',
                  onTap: () => onFilterChanged('SOLD'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Brouillons',
                  selected: filter == 'DRAFT',
                  onTap: () => onFilterChanged('DRAFT'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const _LoadingState(),
            error: (e, _) => _ErrorState(
              message: apiErrorMessage(e, strings),
              onRetry: () => ref.invalidate(adminListingsProvider(filter)),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucune annonce',
                  subtitle: 'Aucune annonce ne correspond à ce filtre.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = MediaQuery.sizeOf(context);
                  final crossAxisCount =
                      AppBreakpoints.adminListingsCrossAxisCount(size);
                  final aspectRatio =
                      AppBreakpoints.adminListingsChildAspectRatio(size);

                  return RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: () async =>
                        ref.invalidate(adminListingsProvider(filter)),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final item = listings[index];
                        return _ListingAdminCard(
                          item: item,
                          dateFmt: dateFmt,
                          strings: strings,
                          compact: crossAxisCount >= 6,
                          onTap: () => context.push('/listing/${item.id}'),
                          onStatusChanged: (status) async {
                            try {
                              await ref
                                  .read(adminServiceProvider)
                                  .updateListingStatus(item.id, status);
                              await onChanged();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      apiErrorMessage(e, strings),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Color _adminListingStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return const Color(0xFF0F766E);
    case 'MODERATED':
      return const Color(0xFFB45309);
    case 'SOLD':
      return AppColors.primaryBlue;
    case 'DRAFT':
      return Colors.blueGrey;
    default:
      return AppColors.primaryBlue;
  }
}

class _ListingAdminCard extends StatelessWidget {
  const _ListingAdminCard({
    required this.item,
    required this.dateFmt,
    required this.strings,
    required this.compact,
    required this.onTap,
    required this.onStatusChanged,
  });

  final AdminListingRow item;
  final DateFormat dateFmt;
  final dynamic strings;
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = _adminListingStatusColor(item.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 34 : 40,
                    height: compact ? 34 : 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      size: compact ? 18 : 20,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    tooltip: 'Changer le statut',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: onStatusChanged,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'ACTIVE', child: Text('Activer')),
                      PopupMenuItem(
                        value: 'MODERATED',
                        child: Text('Modérer'),
                      ),
                      PopupMenuItem(
                        value: 'SOLD',
                        child: Text('Marquer vendue'),
                      ),
                      PopupMenuItem(value: 'DRAFT', child: Text('Brouillon')),
                    ],
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: compact ? 18 : 22,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.ownerName ?? 'Sans vendeur',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: compact ? 10 : 12,
                ),
              ),
              if (item.city.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusBadge(status: item.status),
                  Text(
                    CurrencyFormat.format(item.price, strings.locale),
                    style: TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateFmt.format(item.createdAt.toLocal()),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: compact ? 9 : 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primaryBlue
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final meta = switch (status.toUpperCase()) {
      'PENDING' => (
        'En attente',
        const Color(0xFFB45309),
      ),
      'PAID' => (
        'Confirmé',
        const Color(0xFF0F766E),
      ),
      'REJECTED' => (
        'Refusé',
        AppColors.accentRed,
      ),
      'ACTIVE' => (
        'Active',
        const Color(0xFF0F766E),
      ),
      'MODERATED' => (
        'Modérée',
        const Color(0xFFB45309),
      ),
      'SOLD' => (
        'Vendue',
        AppColors.primaryBlue,
      ),
      'DRAFT' => (
        'Brouillon',
        Colors.blueGrey,
      ),
      _ => (status, AppColors.primaryBlue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: meta.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meta.$1,
        style: TextStyle(
          color: meta.$2,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.accentRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
