import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Retour : page précédente ou profil.
void adminGoBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/profile');
  }
}

/// Accueil marketplace.
void adminGoHome(BuildContext context) {
  context.go('/');
}

/// Boutons Retour + Accueil en bas des écrans admin.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => adminGoBack(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(strings.back),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => adminGoHome(context),
                  icon: const Icon(Icons.home_rounded, size: 20),
                  label: Text(strings.home),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icônes Retour (leading) et Accueil pour AppBar / SliverAppBar.
class AdminNavIconButtons {
  const AdminNavIconButtons._();

  static Widget leading(BuildContext context, AppStrings strings) {
    return IconButton(
      tooltip: strings.back,
      onPressed: () => adminGoBack(context),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  static Widget home(BuildContext context, AppStrings strings) {
    return IconButton(
      tooltip: strings.home,
      onPressed: () => adminGoHome(context),
      icon: const Icon(Icons.home_rounded),
    );
  }
}

/// AppBar standard pour les sous-pages admin.
PreferredSizeWidget adminSubPageAppBar({
  required BuildContext context,
  required AppStrings strings,
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: AppColors.backgroundLight,
    elevation: 0,
    leading: AdminNavIconButtons.leading(context, strings),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
    ),
    actions: [
      ...?actions,
      AdminNavIconButtons.home(context, strings),
      const SizedBox(width: 4),
    ],
  );
}
