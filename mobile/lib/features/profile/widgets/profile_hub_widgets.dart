import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';

class ProfileHubTitle extends StatelessWidget {
  const ProfileHubTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatar,
    this.showAppLogo = false,
    this.onAvatarTap,
    this.isSaving = false,
  });

  final String title;
  final String subtitle;
  final Widget? avatar;
  final bool showAppLogo;
  final VoidCallback? onAvatarTap;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E5BB8),
            AppColors.primaryBlue,
            Color(0xFF002663),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (avatar != null)
            GestureDetector(
              onTap: isSaving ? null : onAvatarTap,
              child: avatar,
            )
          else if (showAppLogo)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const AppLogo(size: 64),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileHubButton extends StatelessWidget {
  const ProfileHubButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.person_add_alt_1_outlined,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({
    super.key,
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(leadingIcon, color: leadingColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileLinkTile extends StatelessWidget {
  const ProfileLinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

Widget profileLocaleTrailing(AppLocale locale) {
  final flag = switch (locale) {
    AppLocale.fr => '🇫🇷',
    AppLocale.ar => '🇹🇩',
    AppLocale.en => '🇬🇧',
  };
  return Text(flag, style: const TextStyle(fontSize: 22));
}

Future<void> showProfileLanguagePicker({
  required BuildContext context,
  required AppStrings strings,
  required AppLocale current,
  required ValueChanged<AppLocale> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.defaultLanguage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final loc in AppLocale.values)
            ListTile(
              leading: profileLocaleTrailing(loc),
              title: Text(strings.languageName(loc)),
              trailing: current == loc
                  ? const Icon(Icons.check, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                onSelected(loc);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

void showAboutAppSheet({
  required BuildContext context,
  required AppStrings strings,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.aboutApp,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: _AboutAppBody(strings: strings),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AboutAppBody extends StatefulWidget {
  const _AboutAppBody({required this.strings});

  final AppStrings strings;

  @override
  State<_AboutAppBody> createState() => _AboutAppBodyState();
}

class _AboutAppBodyState extends State<_AboutAppBody> {
  late final TapGestureRecognizer _companyLinkRecognizer;

  @override
  void initState() {
    super.initState();
    _companyLinkRecognizer = TapGestureRecognizer()
      ..onTap = () async {
        final uri = Uri.parse(widget.strings.experienceTechWebsite);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      };
  }

  @override
  void dispose() {
    _companyLinkRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final company = strings.experienceTechCompanyName;
    final body = strings.aboutAppBody;
    final parts = body.split(company);
    final baseStyle = TextStyle(
      height: 1.55,
      fontSize: 14,
      color: Theme.of(context).colorScheme.onSurface,
    );

    if (parts.length != 2) {
      return Text(body, style: baseStyle);
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: company,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: _companyLinkRecognizer,
          ),
          TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}

void showProfileInfoSheet({
  required BuildContext context,
  required String title,
  required String body,
  String? actionLabel,
  VoidCallback? onAction,
  IconData actionIcon = Icons.mail_outline,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: const TextStyle(height: 1.55, fontSize: 14),
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onAction();
                },
                icon: Icon(actionIcon),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
