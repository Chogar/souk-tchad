import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bouton retour toujours visible : revient à la page précédente,
/// ou à l'accueil quand la pile est vide (arrivée par URL directe
/// ou après la redirection de connexion).
class BackOrHomeButton extends StatelessWidget {
  const BackOrHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
