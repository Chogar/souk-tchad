import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';

final adminPaymentSettingsProvider =
    FutureProvider.autoDispose<AdminPaymentSettings>((ref) {
  return ref.watch(adminServiceProvider).getPaymentSettings();
});

enum AdminPaymentSettingsVariant { profile, page }

/// Formulaire admin : numéros Airtel/Moov + notifications e-mail.
class AdminPaymentSettingsPanel extends ConsumerStatefulWidget {
  const AdminPaymentSettingsPanel({
    super.key,
    this.variant = AdminPaymentSettingsVariant.profile,
    this.embedded = false,
    this.onSaved,
  });

  final AdminPaymentSettingsVariant variant;
  /// Dans le profil : formulaire sans carte ni en-tête (section repliable).
  final bool embedded;
  final VoidCallback? onSaved;

  @override
  ConsumerState<AdminPaymentSettingsPanel> createState() =>
      _AdminPaymentSettingsPanelState();
}

class _AdminPaymentSettingsPanelState
    extends ConsumerState<AdminPaymentSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  final _airtelController = TextEditingController();
  final _moovController = TextEditingController();
  final _emailController = TextEditingController();
  bool _notifyOnPayment = true;
  bool _loaded = false;
  bool _saving = false;

  bool get _isPage => widget.variant == AdminPaymentSettingsVariant.page;

  @override
  void dispose() {
    _airtelController.dispose();
    _moovController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applySettings(AdminPaymentSettings settings) {
    if (_loaded) return;
    _airtelController.text = settings.airtelMoneyNumber;
    _moovController.text = settings.moovMoneyNumber;
    _emailController.text = settings.notificationEmail;
    _notifyOnPayment = settings.notifyOnPayment;
    _loaded = true;
  }

  String? _phoneValidator(String? value, AppStrings strings) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < 8) {
      return strings.adminPaymentPhoneRequired;
    }
    return null;
  }

  Future<void> _save(AppStrings strings) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(adminServiceProvider).updatePaymentSettings(
            airtelMoneyNumber: _airtelController.text,
            moovMoneyNumber: _moovController.text,
            notificationEmail: _emailController.text,
            notifyOnPayment: _notifyOnPayment,
          );
      ref.invalidate(adminPaymentSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.adminPaymentSettingsSaved)),
      );
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, strings))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminPaymentSettingsProvider);
    final strings = ref.watch(stringsProvider);

    return settingsAsync.when(
      loading: () => _wrapShell(
        embedded: widget.embedded,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _wrapShell(
        embedded: widget.embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isPage && !widget.embedded) _buildPageHeader(strings),
            Text(apiErrorMessage(e, strings)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(adminPaymentSettingsProvider),
              child: Text(strings.retry),
            ),
          ],
        ),
      ),
      data: (settings) {
        _applySettings(settings);
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isPage) ...[
                _PaymentSettingsHero(strings: strings),
                const SizedBox(height: 16),
                _ClientPreviewCard(
                  strings: strings,
                  airtel: _airtelController.text,
                  moov: _moovController.text,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: strings.adminPaymentNumbersSection,
                  icon: Icons.phone_android_outlined,
                  iconColor: AppColors.primaryBlue,
                  child: Column(
                    children: _buildFormFields(strings),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: strings.adminPaymentNotificationsTitle,
                  icon: Icons.mail_outline,
                  iconColor: AppColors.accentRed,
                  child: _buildNotificationFields(strings),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(strings),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(strings.save),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ] else if (widget.embedded)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildFormFields(strings),
                    _buildNotificationFields(strings),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(strings),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.save),
                    ),
                  ],
                )
              else
                _wrapShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeader(strings),
                      const SizedBox(height: 16),
                      ..._buildFormFields(strings),
                      _buildNotificationFields(strings),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving ? null : () => _save(strings),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(strings.save),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _wrapShell({required Widget child, bool embedded = false}) {
    if (_isPage || embedded) return child;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: child,
    );
  }

  Widget _buildProfileHeader(AppStrings strings) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Color(0xFF8A6D00),
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.adminPaymentSettingsTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.adminPaymentSettingsProfileSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(AppStrings strings) {
    return Text(
      strings.adminPaymentSettingsTitle,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }

  List<Widget> _buildFormFields(AppStrings strings) {
    return [
      _OperatorNumberField(
        label: strings.airtelMoney,
        fieldLabel: strings.airtelMoneyNumberLabel,
        controller: _airtelController,
        enabled: !_saving,
        accent: AppColors.accentRed,
        validator: (v) => _phoneValidator(v, strings),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      _OperatorNumberField(
        label: strings.moovMoney,
        fieldLabel: strings.moovMoneyNumberLabel,
        controller: _moovController,
        enabled: !_saving,
        accent: const Color(0xFF0066CC),
        validator: (v) => _phoneValidator(v, strings),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 8),
      Text(
        strings.adminPaymentNumbersHint,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    ];
  }

  Widget _buildNotificationFields(AppStrings strings) {
    if (!_isPage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            strings.adminPaymentNotificationsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            enabled: !_saving,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: strings.adminPaymentNotificationEmail,
              hintText: 'admin@example.com',
              prefixIcon: const Icon(Icons.mail_outline),
              filled: true,
              fillColor: AppColors.backgroundLight,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              strings.adminPaymentNotifyOnPayment,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              strings.adminPaymentNotifyOnPaymentHint,
              style: const TextStyle(fontSize: 11),
            ),
            value: _notifyOnPayment,
            onChanged:
                _saving ? null : (v) => setState(() => _notifyOnPayment = v),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextField(
          controller: _emailController,
          enabled: !_saving,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: strings.adminPaymentNotificationEmail,
            hintText: 'admin@example.com',
            prefixIcon: const Icon(Icons.mail_outline),
            filled: true,
            fillColor: AppColors.backgroundLight,
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.adminPaymentNotifyOnPayment),
          subtitle: Text(
            strings.adminPaymentNotifyOnPaymentHint,
            style: const TextStyle(fontSize: 12),
          ),
          value: _notifyOnPayment,
          onChanged:
              _saving ? null : (v) => setState(() => _notifyOnPayment = v),
        ),
      ],
    );
  }
}

class _PaymentSettingsHero extends StatelessWidget {
  const _PaymentSettingsHero({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001A44),
            AppColors.primaryBlue,
            Color(0xFF0A3A7A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.accentGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.adminPaymentSettingsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.adminPaymentFlowHint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientPreviewCard extends StatelessWidget {
  const _ClientPreviewCard({
    required this.strings,
    required this.airtel,
    required this.moov,
  });

  final AppStrings strings;
  final String airtel;
  final String moov;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                strings.adminPaymentPreviewTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PreviewChip(
                  label: strings.airtelMoney,
                  number: airtel.isEmpty ? '—' : airtel,
                  color: AppColors.accentRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreviewChip(
                  label: strings.moovMoney,
                  number: moov.isEmpty ? '—' : moov,
                  color: const Color(0xFF0066CC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.number,
    required this.color,
  });

  final String label;
  final String number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OperatorNumberField extends StatelessWidget {
  const _OperatorNumberField({
    required this.label,
    required this.fieldLabel,
    required this.controller,
    required this.accent,
    required this.validator,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final String fieldLabel;
  final TextEditingController controller;
  final Color accent;
  final String? Function(String?) validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            validator: validator,
            onChanged: onChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
            ],
            decoration: InputDecoration(
              labelText: fieldLabel,
              hintText: '+235 66 00 00 00',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.phone_android_outlined, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
