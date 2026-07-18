import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/registration_flow_provider.dart';
import '../../../core/providers/server_config_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/google_auth_button.dart';
import '../../home/providers/listings_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    this.asModal = false,
    this.redirectPath,
    this.onClose,
    this.onAlreadyHaveAccount,
  });

  final bool asModal;
  final String? redirectPath;
  final VoidCallback? onClose;
  final VoidCallback? onAlreadyHaveAccount;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onAuthSuccess() async {
    try {
      await ref.read(apiBaseUrlProvider.future);
      await ref.read(listingsProvider(defaultListingsFilter).future);
    } catch (_) {}
    if (!mounted) return;

    final redirect = widget.redirectPath;

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

  Future<void> _sendOtpAndContinue(String email) async {
    setState(() => _isLoading = true);
    try {
      final result =
          await ref.read(authStateProvider.notifier).sendRegistrationOtp(email);
      ref.read(registrationDraftProvider.notifier).setDraft(
            RegistrationDraft(
              email: email,
              devCode: result.devCode,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      if (widget.asModal) {
        widget.onClose?.call();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!context.mounted) return;
      context.push('/register/verify');
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e, strings)),
          action: apiErrorMessage(e, strings) == strings.emailAlreadyUsed
              ? SnackBarAction(
                  label: strings.login,
                  onPressed: _openLogin,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _sendOtpAndContinue(_emailController.text.trim().toLowerCase());
  }

  void _openLogin() {
    if (widget.asModal && widget.onAlreadyHaveAccount != null) {
      widget.onAlreadyHaveAccount!();
      return;
    }
    if (widget.asModal) {
      widget.onClose?.call();
    }
    context.go('/login');
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryBlue),
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
        AppLogo(size: widget.asModal ? 72 : 100),
        const SizedBox(height: 10),
        Text(
          strings.createAccount,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final authState = ref.watch(authStateProvider);
    final busy = _isLoading || authState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GoogleAuthButton(
            label: strings.googleRegister,
            onSuccess: () => _onAuthSuccess(),
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
          Text(
            strings.registerEmailHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: _fieldDecoration(
              label: strings.email,
              icon: Icons.email_outlined,
            ),
            validator: (v) =>
                v != null && v.contains('@') ? null : strings.invalidEmail,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.continueLabel),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : _openLogin,
            child: Text(strings.alreadyHaveAccount),
          ),
          if (!widget.asModal)
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(strings.browseWithoutAccount),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        final message = apiErrorMessage(next.error!, strings);
        if (message.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      final wasLoggedIn = previous?.value != null;
      final isLoggedIn = next.hasValue && next.value != null;
      if (!wasLoggedIn && isLoggedIn && !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthSuccess());
      }
    });

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 18),
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
      appBar: AppBar(
        title: Text(strings.createAccount),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
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
