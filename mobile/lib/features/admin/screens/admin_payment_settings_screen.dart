import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive_center.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/keyboard_scroll_view.dart';
import '../widgets/admin_nav_bar.dart';
import '../widgets/admin_payment_settings_panel.dart';

class AdminPaymentSettingsScreen extends ConsumerWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: adminSubPageAppBar(
        context: context,
        strings: strings,
        title: strings.adminPaymentSettingsTitle,
        actions: [
          IconButton(
            tooltip: strings.adminDashboardLink,
            onPressed: () => context.push('/admin'),
            icon: const Icon(Icons.dashboard_customize_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(strings: strings),
      body: SafeArea(
        child: KeyboardScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ResponsiveCenter(
            maxWidth: 560,
            child: const AdminPaymentSettingsPanel(
              variant: AdminPaymentSettingsVariant.page,
            ),
          ),
        ),
      ),
    );
  }
}
