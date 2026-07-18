import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

/// Ouvre la connexion dans une modale centrée.
Future<void> showLoginModal(
  BuildContext context, {
  String? redirectPath,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 720),
          child: LoginScreen(
            asModal: true,
            redirectPath: redirectPath,
            onClose: () => Navigator.of(dialogContext).pop(),
            onCreateAccount: () {
              Navigator.of(dialogContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showRegisterModal(context, redirectPath: redirectPath);
                }
              });
            },
          ),
        ),
      );
    },
  );
}

/// Ouvre l'inscription (Google + e-mail) dans une modale centrée.
Future<void> showRegisterModal(
  BuildContext context, {
  String? redirectPath,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 720),
          child: RegisterScreen(
            asModal: true,
            redirectPath: redirectPath,
            onClose: () => Navigator.of(dialogContext).pop(),
            onAlreadyHaveAccount: () {
              Navigator.of(dialogContext).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  showLoginModal(context, redirectPath: redirectPath);
                }
              });
            },
          ),
        ),
      );
    },
  );
}
