import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/auth_modals.dart';

class AuthRequiredView extends ConsumerWidget {
  const AuthRequiredView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.redirectPath,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? redirectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showLoginModal(
                  context,
                  redirectPath: redirectPath,
                ),
                icon: const Icon(Icons.login),
                label: Text(strings.login),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showRegisterModal(
                  context,
                  redirectPath: redirectPath,
                ),
                icon: const Icon(Icons.person_add_outlined),
                label: Text(strings.createAccount),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(shellTabIndexProvider.notifier).setIndex(0),
              child: Text(strings.browseWithoutAccount),
            ),
          ],
        ),
      ),
    );
  }
}
