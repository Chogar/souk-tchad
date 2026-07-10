import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/subscriptions_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../listings/utils/listing_media_picker.dart';

/// Affiche le modal de paiement Mobile Money pour un plan payant.
Future<void> showPaymentModal({
  required BuildContext context,
  required PlanModel plan,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: _PaymentModalBody(plan: plan),
    ),
  );
}

enum _MomoProvider { airtel, moov }

class _PaymentModalBody extends ConsumerStatefulWidget {
  const _PaymentModalBody({required this.plan});

  final PlanModel plan;

  @override
  ConsumerState<_PaymentModalBody> createState() => _PaymentModalBodyState();
}

class _PaymentModalBodyState extends ConsumerState<_PaymentModalBody> {
  _MomoProvider _provider = _MomoProvider.airtel;
  XFile? _proofImage;
  Uint8List? _proofPreview;
  bool _loading = false;
  bool _loadingInstructions = true;
  String? _error;
  PaymentInstructions? _instructions;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  Future<void> _loadInstructions() async {
    try {
      final instructions =
          await ref.read(subscriptionsServiceProvider).getPaymentInstructions();
      if (!mounted) return;
      setState(() {
        _instructions = instructions;
        _loadingInstructions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingInstructions = false);
    }
  }

  String? _selectedRecipientNumber() {
    final instructions = _instructions;
    if (instructions == null) return null;
    final key = _provider == _MomoProvider.airtel
        ? 'airtel_money'
        : 'moov_money';
    final number = instructions.numberForProvider(key).trim();
    return number.isEmpty ? null : number;
  }

  Future<void> _copyNumber(String number, AppStrings strings) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.paymentNumberCopied)),
    );
  }

  Future<void> _pickProof() async {
    final strings = ref.read(stringsProvider);
    final source = await showPhotoSourceSheet(context, strings);
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _proofImage = file;
      _proofPreview = bytes;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final strings = ref.read(stringsProvider);
    final recipient = _selectedRecipientNumber();
    if (recipient == null) {
      setState(() => _error = strings.adminPaymentPhoneRequired);
      return;
    }
    if (_proofImage == null) {
      setState(() => _error = strings.paymentProofRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(subscriptionsServiceProvider).checkout(
            planId: widget.plan.id,
            provider: _provider == _MomoProvider.airtel
                ? 'airtel_money'
                : 'moov_money',
            proofImage: _proofImage!,
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, strings);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final plan = widget.plan;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final recipient = _selectedRecipientNumber();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: _submitted
              ? _SuccessView(
                  strings: strings,
                  onClose: () => Navigator.pop(context),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.paymentModalTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.paymentModalSubtitle(plan.name),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: strings.amountToSend,
                        prefixIcon: const Icon(Icons.payments_outlined),
                        suffixText: 'FCFA',
                        filled: true,
                      ),
                      child: Text(
                        '${plan.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.momoOperatorLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OperatorChip(
                            label: strings.airtelMoney,
                            number: _instructions?.airtelMoneyNumber,
                            selected: _provider == _MomoProvider.airtel,
                            accent: AppColors.accentRed,
                            onTap: _loading
                                ? null
                                : () => setState(
                                      () => _provider = _MomoProvider.airtel,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _OperatorChip(
                            label: strings.moovMoney,
                            number: _instructions?.moovMoneyNumber,
                            selected: _provider == _MomoProvider.moov,
                            accent: const Color(0xFF0066CC),
                            onTap: _loading
                                ? null
                                : () => setState(
                                      () => _provider = _MomoProvider.moov,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    if (_loadingInstructions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (recipient != null) ...[
                      const SizedBox(height: 12),
                      _RecipientCard(
                        label: _provider == _MomoProvider.airtel
                            ? strings.airtelMoney
                            : strings.moovMoney,
                        amount: '${plan.price}',
                        number: recipient,
                        strings: strings,
                        onCopy: () => _copyNumber(recipient, strings),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          strings.paymentNumberNotConfigured,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      strings.paymentProofLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.paymentProofHint,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _loading ? null : _pickProof,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _proofPreview == null
                                ? Colors.grey.shade300
                                : AppColors.primaryBlue,
                          ),
                          color: Colors.grey.shade50,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _proofPreview != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    _proofPreview!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Material(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        onPressed:
                                            _loading ? null : _pickProof,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 36,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    strings.addPaymentScreenshot,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(strings.submitPaymentRequest),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.pop(context),
                      child: Text(strings.cancel),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.label,
    required this.amount,
    required this.number,
    required this.strings,
    required this.onCopy,
  });

  final String label;
  final String amount;
  final String number;
  final AppStrings strings;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.paymentSendTo(amount, number),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: AppColors.primaryBlue.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorChip extends StatelessWidget {
  const _OperatorChip({
    required this.label,
    required this.number,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String? number;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayNumber = (number ?? '').trim();

    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: selected ? accent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? accent : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (selected && displayNumber.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  displayNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.strings,
    required this.onClose,
  });

  final AppStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.primaryBlue,
          size: 56,
        ),
        const SizedBox(height: 12),
        Text(
          strings.paymentRequestSentTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.paymentRequestSentBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onClose,
          child: Text(strings.close),
        ),
      ],
    );
  }
}
