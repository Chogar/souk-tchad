import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/registration_flow_provider.dart';
import '../../../core/utils/google_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/keyboard_scroll_view.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

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
                  onPressed: () => context.go('/login'),
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

  Future<void> _pickGmail() async {
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
    try {
      final email = await ref.read(authServiceProvider).pickGoogleEmail();
      if (email == null || email.isEmpty) return;
      _emailController.text = email;
      await _sendOtpAndContinue(email.trim().toLowerCase());
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      final message = apiErrorMessage(e, strings);
      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(strings.createAccount)),
      body: SafeArea(
        child: KeyboardScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.registerEmailHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: strings.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    hintText: 'exemple@gmail.com',
                  ),
                  validator: (v) =>
                      v != null && v.contains('@') ? null : strings.invalidEmail,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.continueLabel),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickGmail,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(strings.googleEmailPicker),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(strings.alreadyHaveAccount),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(strings.browseWithoutAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
