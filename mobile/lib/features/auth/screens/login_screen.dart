import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/server_config_provider.dart';
import '../../home/providers/listings_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/keyboard_scroll_view.dart';
import '../../../core/widgets/server_url_panel.dart';
import '../../../core/utils/google_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _credentialsLoaded = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedCredentials());
  }

  Future<void> _loadSavedCredentials() async {
    final credentialsService = ref.read(credentialsServiceProvider);
    await credentialsService.migrate();
    final credentials = await credentialsService.loadSaved();
    if (!mounted || credentials == null) {
      setState(() => _credentialsLoaded = true);
      return;
    }

    setState(() {
      _emailController.text = credentials.email;
      _passwordController.text = credentials.password;
      _rememberMe = true;
      _credentialsLoaded = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text.trim(),
          remember: _rememberMe,
        );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _googleLogin() async {
    if (!isGoogleSignInConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(stringsProvider).googleNotConfigured),
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!email.contains('@')) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).resendVerification(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).verificationEmailSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isUnverifiedEmailError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('non vérifié') ||
        lower.contains('non verifie') ||
        lower.contains('not verified') ||
        lower.contains('غير موثق');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final strings = ref.watch(stringsProvider);
    final serverUrl = ref.watch(apiBaseUrlProvider).value;
    final showServerConfig = serverUrl == null ||
        serverUrl.contains('127.0.0.1') ||
        serverUrl.contains('localhost');

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        final message = apiErrorMessage(next.error!, strings);
        if (message.isEmpty) return;
        if (message.contains('Identifiants invalides') ||
            message.contains('401')) {
          ref.read(credentialsServiceProvider).clear();
          setState(() {
            _rememberMe = false;
            _passwordController.clear();
          });
        }
        if (_isUnverifiedEmailError(message)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.emailNotVerifiedLogin),
              action: SnackBarAction(
                label: strings.resendVerification,
                onPressed: _resendVerification,
              ),
              duration: const Duration(seconds: 8),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.contains('Identifiants invalides')
                  ? strings.wrongCredentials
                  : message,
            ),
            duration: message == strings.googleNotConfigured
                ? const Duration(seconds: 10)
                : const Duration(seconds: 4),
          ),
        );
        return;
      }

      final wasLoggedIn = previous?.value != null;
      final isLoggedIn = next.hasValue && next.value != null;
      if (!wasLoggedIn && isLoggedIn && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await ref.read(apiBaseUrlProvider.future);
            await ref.read(listingsProvider(defaultListingsFilter).future);
          } catch (_) {}
          if (!context.mounted) return;
          final redirect =
              GoRouterState.of(context).uri.queryParameters['redirect'];
          if (redirect != null && redirect.isNotEmpty) {
            context.go(redirect);
          } else {
            context.go('/');
          }
        });
      }
    });

    if (!_credentialsLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: AppLogo(size: 180)),
                const SizedBox(height: 16),
                Text(
                  strings.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (showServerConfig) ...[
                  const SizedBox(height: 24),
                  ServerUrlPanel(initiallyExpanded: true),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: strings.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : strings.invalidEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: strings.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? strings.showPassword
                          : strings.hidePassword,
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : strings.minPassword,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(strings.rememberMe),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading || authState.isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.login),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed:
                      _isLoading || authState.isLoading ? null : _googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(strings.googleLogin),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(strings.createAccount),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(strings.browseWithoutAccount),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(credentialsServiceProvider).clear();
                    setState(() {
                      _rememberMe = false;
                      _emailController.clear();
                      _passwordController.clear();
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.credentialsCleared)),
                      );
                    }
                  },
                  child: Text(strings.clearCredentials),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
