import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/registration_flow_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/keyboard_scroll_view.dart';

class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final draft = ref.read(registrationDraftProvider);
    if (draft == null) {
      context.go('/register');
      return;
    }

    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(stringsProvider).invalidOtp)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await ref
          .read(authStateProvider.notifier)
          .verifyRegistrationOtp(draft.email, code);
      ref.read(registrationDraftProvider.notifier).setDraft(
            draft.copyWith(registrationToken: token),
          );
      if (!mounted) return;
      context.push('/register/profile');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    final draft = ref.read(registrationDraftProvider);
    if (draft == null) {
      context.go('/register');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(authStateProvider.notifier)
          .sendRegistrationOtp(draft.email);
      ref.read(registrationDraftProvider.notifier).setDraft(
            draft.copyWith(devCode: result.devCode),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, ref.read(stringsProvider)))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final draft = ref.watch(registrationDraftProvider);

    if (draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/register');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(strings.verifyEmailTitle)),
      body: SafeArea(
        child: KeyboardScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.otpSentTo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                draft.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (draft.devCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${strings.devOtpHint} ${draft.devCode}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: strings.otpCode,
                  hintText: strings.otpCodeHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_outlined),
                ),
                onFieldSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.verifyCode),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _resend,
                child: Text(strings.resendOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
