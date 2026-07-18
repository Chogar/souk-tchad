import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/layout/responsive_center.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/back_or_home_button.dart';
import '../../auth/auth_modals.dart';
import '../../home/providers/listings_provider.dart';
import '../providers/my_listings_provider.dart';
import '../utils/listing_media_picker.dart';
import '../../../core/services/listings_bootstrap.dart';

/// Opens the create-listing form in a centered modal.
Future<void> showCreateListingModal(BuildContext context) {
  final container = ProviderScope.containerOf(context);
  final user = container.read(authStateProvider).value;
  if (user == null) {
    return showLoginModal(context, redirectPath: '/create-listing');
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 780),
          child: CreateListingScreen(
            asModal: true,
            onClose: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    },
  );
}

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({
    super.key,
    this.asModal = false,
    this.onClose,
  });

  final bool asModal;
  final VoidCallback? onClose;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  late final TextEditingController _cityController;

  String? _defaultCategoryId;
  String? _defaultCategorySlug;
  final List<XFile> _images = [];
  XFile? _videoFile;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _listening = false;
  final SpeechToText _speech = SpeechToText();

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    if (_listening) {
      _speech.stop();
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories =
        await ref.read(listingsServiceProvider).getCategories();
    if (mounted) {
      final strings = ref.read(stringsProvider);
      if (_cityController.text.isEmpty) {
        _cityController.text = strings.defaultCity;
      }
      // Préférer une catégorie classique ; « autre » en dernier recours.
      final preferred = categories.where((c) => c.slug != kOtherCategorySlug);
      final chosen = preferred.isNotEmpty
          ? preferred.first
          : (categories.isNotEmpty ? categories.first : null);
      setState(() {
        _defaultCategoryId = chosen?.id;
        _defaultCategorySlug = chosen?.slug;
      });
    }
  }

  Future<void> _pickImages() async {
    final strings = ref.read(stringsProvider);
    final source = await showPhotoSourceSheet(context, strings);
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (file == null || _images.length >= 5) return;
      final compressed = await _prepareImage(file, _images.length);
      if (compressed != null) {
        setState(() => _images.add(compressed));
      }
      return;
    }

    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files.isEmpty) return;

    final prepared = <XFile>[];
    var index = _images.length;
    for (final file in files.take(5 - _images.length)) {
      final compressed = await _prepareImage(file, index);
      if (compressed != null) prepared.add(compressed);
      index++;
    }

    setState(() => _images.addAll(prepared));
  }

  Future<void> _pickVideo() async {
    final strings = ref.read(stringsProvider);
    final source = await showVideoSourceSheet(context, strings);
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return;
    setState(() => _videoFile = file);
  }

  Future<XFile?> _prepareImage(XFile file, int index) async {
    if (kIsWeb) return file;

    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}_$index.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      return result != null ? XFile(result.path) : file;
    } catch (_) {
      return file;
    }
  }

  Future<void> _toggleVoiceDictation() async {
    final strings = ref.read(stringsProvider);
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.speechUnavailable)),
        );
      }
      return;
    }

    setState(() => _listening = true);
    final locale = switch (strings.locale.name) {
      'ar' => 'ar_SA',
      'en' => 'en_US',
      _ => 'fr_FR',
    };

    await _speech.listen(
      localeId: locale,
      partialResults: true,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty || !mounted) return;
        setState(() {
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = text;
          } else {
            _descriptionController.text = text;
          }
        });
      },
    );
  }

  Future<void> _improveWithAi() async {
    final strings = ref.read(stringsProvider);
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(aiServiceProvider).improveListing(
            title: _titleController.text,
            description: _descriptionController.text,
          );
      _titleController.text = result['title'] ?? _titleController.text;
      _descriptionController.text =
          result['description'] ?? _descriptionController.text;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorWith(apiErrorMessage(e, strings))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final strings = ref.read(stringsProvider);
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    if (_defaultCategoryId == null) {
      await _loadCategories();
      if (_defaultCategoryId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.errorWith(strings.loadingFailed))),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      final service = ref.read(listingsServiceProvider);
      final title = _titleController.text.trim();
      final customName = _defaultCategorySlug == kOtherCategorySlug
          ? (title.length >= 2 ? title : 'Divers')
          : null;

      var listing = await service.createListing(
        title: title,
        description: _descriptionController.text.trim(),
        price: CurrencyFormat.inputToXaf(
          double.parse(_priceController.text),
          strings.locale,
        ),
        categoryId: _defaultCategoryId!,
        city: _cityController.text.trim(),
        customCategoryName: customName,
      );

      if (_images.isNotEmpty) {
        listing = await service.uploadImages(listing.id, _images);
      }

      if (_videoFile != null) {
        listing = await service.uploadVideo(listing.id, _videoFile!);
      }

      if (!mounted) return;

      // Mise à jour locale unique (évite les rafraîchissements en boucle).
      ListingsBootstrap.upsertListing(listing);
      bumpCatalogVersion(ref);
      ref.invalidate(myListingsProvider);

      final visible = listing.status == 'ACTIVE';
      final message = visible
          ? strings.listingPublished
          : strings.listingModeratedHidden;

      final messenger = ScaffoldMessenger.of(context);
      if (widget.asModal) {
        widget.onClose?.call();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: visible ? 3 : 6),
        ),
      );

      if (!widget.asModal && mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.errorWith(apiErrorMessage(e, strings)))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
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
    );
  }

  Widget _buildForm(BuildContext context) {
    final strings = ref.watch(stringsProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: _fieldDecoration(strings.title),
            validator: (v) =>
                v != null && v.isNotEmpty ? null : strings.titleRequired,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _fieldDecoration(strings.description),
            validator: (v) => v != null && v.isNotEmpty
                ? null
                : strings.descriptionRequired,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _toggleVoiceDictation,
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                  label: Text(
                    _listening ? strings.listening : strings.dictateListing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: _listening
                        ? Colors.white
                        : AppColors.primaryBlue,
                    backgroundColor: _listening
                        ? AppColors.accentRed
                        : AppColors.primaryBlue.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _improveWithAi,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    strings.improveWithAi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(strings.priceLabel),
            validator: (v) {
              if (v == null || v.isEmpty) return strings.priceRequired;
              if (double.tryParse(v) == null) return strings.invalidPrice;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityController,
            decoration: _fieldDecoration(strings.city),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _images.length >= 5 ? null : _pickImages,
            icon: const Icon(Icons.photo_library),
            label: Text(strings.addPhotos(_images.length, 5)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          if (_images.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PickedImageThumb(
                        bytesFuture: _images[index].readAsBytes(),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(
                          () => _images.removeAt(index),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              if (_videoFile != null) {
                setState(() => _videoFile = null);
              } else {
                _pickVideo();
              }
            },
            icon: Icon(
              _videoFile != null
                  ? Icons.videocam_off_outlined
                  : Icons.videocam_outlined,
            ),
            label: Text(
              _videoFile != null ? strings.removeVideo : strings.addVideo,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (_videoFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.addVideo,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      strings.publish,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    if (_defaultCategoryId == null && !_isLoading) {
      _loadCategories();
    }

    final formBody = _buildForm(context);

    if (widget.asModal) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        shadowColor: Colors.black26,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      strings.createListing,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: formBody,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(strings.createListing),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ResponsiveCenter(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: formBody,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
