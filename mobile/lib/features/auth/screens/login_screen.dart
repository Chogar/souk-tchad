import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/server_config_provider.dart';
import '../../home/providers/listings_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/google_auth_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.asModal = false,
    this.redirectPath,
    this.onClose,
    this.onCreateAccount,
  });

  final bool asModal;
  final String? redirectPath;
  final VoidCallback? onClose;
  final VoidCallback? onCreateAccount;

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

  Future<void> _onLoginSuccess() async {
    try {
      await ref.read(apiBaseUrlProvider.future);
      await ref.read(listingsProvider(defaultListingsFilter).future);
    } catch (_) {}
    if (!mounted) return;

    final redirect = widget.redirectPath ??
        (widget.asModal
            ? null
            : GoRouterState.of(context).uri.queryParameters['redirect']);

    if (widget.asModal) {
      widget.onClose?.call();
      if (redirect != null && redirect.isNotEmpty && context.mounted) {
        context.go(redirect);
      }
      return;
    }

    if (redirect != null && redirect.isNotEmpty) {
      context.go(redirect);
    } else {
      context.go('/');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildForm(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final strings = ref.watch(stringsProvider);
    final busy = _isLoading || authState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _fieldDecoration(
              label: strings.email,
              icon: Icons.email_outlined,
            ),
            validator: (v) =>
                v != null && v.contains('@') ? null : strings.invalidEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            autocorrect: false,
            enableSuggestions: false,
            decoration: _fieldDecoration(
              label: strings.password,
              icon: Icons.lock_outline,
              suffix: IconButton(
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
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                height: 36,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                  activeColor: AppColors.primaryBlue,
                ),
              ),
              Expanded(child: Text(strings.rememberMe)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      strings.login,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          GoogleAuthButton(
            label: strings.googleLogin,
            onSuccess: () => _onLoginSuccess(),
          ),
          const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                if (widget.asModal && widget.onCreateAccount != null) {
                  widget.onCreateAccount!();
                } else if (widget.asModal) {
                  widget.onClose?.call();
                  context.push('/register');
                } else {
                  context.push('/register');
                }
              },
              child: Text(
                strings.createAccount,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentRed,
                ),
              ),
            ),
          if (!widget.asModal) ...[
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    return Column(
      children: [
        if (widget.asModal)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ),
        AppLogo(size: widget.asModal ? 88 : 140),
        const SizedBox(height: 10),
        Text(
          strings.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.appTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.loginOrRegister,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

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
        WidgetsBinding.instance.addPostFrameCallback((_) => _onLoginSuccess());
      }
    });

    if (!_credentialsLoaded) {
      if (widget.asModal) {
        return const Material(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 20),
        _buildForm(context),
      ],
    );

    if (widget.asModal) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: content,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
