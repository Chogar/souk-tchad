import 'package:flutter/material.dart';

/// Ferme le clavier quand on tape en dehors d'un champ de saisie.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  static void unfocus(BuildContext context) {
    final focus = FocusScope.of(context);
    if (focus.hasFocus) {
      focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => unfocus(context),
      child: child,
    );
  }
}
