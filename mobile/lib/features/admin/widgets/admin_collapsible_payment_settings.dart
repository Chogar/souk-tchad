import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_payment_settings_panel.dart';

/// Section repliable profil admin : clic pour ouvrir, repli après enregistrement.
class AdminCollapsiblePaymentSettings extends ConsumerStatefulWidget {
  const AdminCollapsiblePaymentSettings({super.key});

  @override
  ConsumerState<AdminCollapsiblePaymentSettings> createState() =>
      _AdminCollapsiblePaymentSettingsState();
}

class _AdminCollapsiblePaymentSettingsState
    extends ConsumerState<AdminCollapsiblePaymentSettings> {
  bool _expanded = false;

  String _collapsedSubtitle(String tapToConfigure) {
    final settings = ref.watch(adminPaymentSettingsProvider);
    return settings.when(
      data: (s) {
        final airtel = s.airtelMoneyNumber.trim();
        final moov = s.moovMoneyNumber.trim();
        if (airtel.isEmpty && moov.isEmpty) {
          return tapToConfigure;
        }
        final parts = <String>[];
        if (airtel.isNotEmpty) parts.add('Airtel $airtel');
        if (moov.isNotEmpty) parts.add('Moov $moov');
        return parts.join(' · ');
      },
      loading: () => tapToConfigure,
      error: (_, __) => tapToConfigure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? AppColors.accentGold.withValues(alpha: 0.5)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF8A6D00),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.adminPaymentSettingsTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expanded
                                ? strings.adminPaymentTapToCollapse
                                : _collapsedSubtitle(
                                    strings.adminPaymentTapToConfigure,
                                  ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: AdminPaymentSettingsPanel(
                        embedded: true,
                        onSaved: () => setState(() => _expanded = false),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
