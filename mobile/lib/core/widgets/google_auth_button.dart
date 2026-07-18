import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/app_providers.dart';
import '../providers/locale_provider.dart';
import '../theme/app_colors.dart';
import '../utils/api_error.dart';
import '../utils/google_config.dart';
import 'google_gis_button_stub.dart'
    if (dart.library.html) 'google_gis_button_web.dart' as gis;

/// Bouton Google multi-plateforme.
/// - iOS/Android : bouton custom + `authenticate()`
/// - Web : bouton GIS officiel (`renderButton`) — `authenticate()` ne marche pas
class GoogleAuthButton extends ConsumerStatefulWidget {
  const GoogleAuthButton({
    super.key,
    required this.label,
    this.onSuccess,
    this.onBusyChanged,
  });

  final String label;
  final VoidCallback? onSuccess;
  final ValueChanged<bool>? onBusyChanged;

  @override
  ConsumerState<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends ConsumerState<GoogleAuthButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webSub;
  bool _busy = false;
  bool _webReady = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _prepareWeb();
    }
  }

  Future<void> _prepareWeb() async {
    try {
      await ref.read(authServiceProvider).initGoogle();
      _webSub?.cancel();
      _webSub = GoogleSignIn.instance.authenticationEvents.listen(
        _onWebAuthEvent,
        onError: _onWebAuthError,
      );
      if (mounted) setState(() => _webReady = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e, ref.read(stringsProvider))),
        ),
      );
    }
  }

  Future<void> _onWebAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    if (_busy) return;

    _setBusy(true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .loginWithGoogleAccount(event.user);
      if (!mounted) return;
      final auth = ref.read(authStateProvider);
      if (auth.hasError) {
        final message = apiErrorMessage(auth.error!, ref.read(stringsProvider));
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }
      widget.onSuccess?.call();
    } finally {
      _setBusy(false);
    }
  }

  void _onWebAuthError(Object error) {
    if (!mounted) return;
    final message = apiErrorMessage(error, ref.read(stringsProvider));
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _setBusy(bool value) {
    if (!mounted) return;
    setState(() => _busy = value);
    widget.onBusyChanged?.call(value);
  }

  Future<void> _nativeGoogle() async {
    if (!isGoogleSignInConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(stringsProvider).googleNotConfigured),
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    _setBusy(true);
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      final auth = ref.read(authStateProvider);
      if (auth.hasError) {
        final message = apiErrorMessage(auth.error!, ref.read(stringsProvider));
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }
      if (auth.value != null) widget.onSuccess?.call();
    } finally {
      _setBusy(false);
    }
  }

  @override
  void dispose() {
    _webSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isGoogleSignInConfigured) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: Text(widget.label),
      );
    }

    // Web : bouton GIS obligatoire (authenticate() ne fonctionne pas).
    if (kIsWeb || !GoogleSignIn.instance.supportsAuthenticate()) {
      if (!_webReady) {
        return const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: gis.renderGoogleGisButton()),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _nativeGoogle,
        icon: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 28),
        label: Text(widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
