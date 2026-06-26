import 'package:flutter/material.dart';
import 'dismiss_keyboard.dart';

/// Scroll view qui remonte le contenu quand le clavier s'ouvre.
class KeyboardScrollView extends StatelessWidget {
  const KeyboardScrollView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DismissKeyboard(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding.copyWith(bottom: padding.bottom + bottomInset),
        child: child,
      ),
    );
  }
}
