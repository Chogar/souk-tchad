import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/currency_format.dart';
import '../../home/providers/listings_provider.dart';
import '../providers/my_listings_provider.dart';
import '../utils/listing_media_picker.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

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
  final _customCategoryController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  final List<String> _imagePaths = [];
  String? _videoPath;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  bool get _isOtherCategory {
    if (_selectedCategoryId == null) return false;
    final match = _categories.where((c) => c.id == _selectedCategoryId);
    return match.isNotEmpty && match.first.slug == kOtherCategorySlug;
  }

  Future<void> _loadCategories() async {
    final categories =
        await ref.read(listingsServiceProvider).getCategories();
    if (mounted) {
      final strings = ref.read(stringsProvider);
      if (_cityController.text.isEmpty) {
        _cityController.text = strings.defaultCity;
      }
      setState(() {
        _categories = categories;
        _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
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
      if (file == null || _imagePaths.length >= 5) return;
      final compressed = await _compressImage(file.path, _imagePaths.length);
      if (compressed != null) {
        setState(() => _imagePaths.add(compressed));
      }
      return;
    }

    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files.isEmpty) return;

    final compressedPaths = <String>[];
    var index = _imagePaths.length;
    for (final file in files.take(5 - _imagePaths.length)) {
      final compressed = await _compressImage(file.path, index);
      if (compressed != null) compressedPaths.add(compressed);
      index++;
    }

    setState(() => _imagePaths.addAll(compressedPaths));
  }

  Future<void> _pickVideo() async {
    if (kIsWeb) return;
    final strings = ref.read(stringsProvider);
    final source = await showVideoSourceSheet(context, strings);
    if (source == null || !mounted) return;

    final file = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return;
    setState(() => _videoPath = file.path);
  }

  Future<String?> _compressImage(String path, int index) async {
    if (kIsWeb) return path;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}_$index.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );

    return result?.path;
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
    if (_isSubmitting ||
        !_formKey.currentState!.validate() ||
        _selectedCategoryId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      final service = ref.read(listingsServiceProvider);
      var listing = await service.createListing(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: CurrencyFormat.inputToXaf(
          double.parse(_priceController.text),
          strings.locale,
        ),
        categoryId: _selectedCategoryId!,
        city: _cityController.text.trim(),
        customCategoryName: _isOtherCategory
            ? _customCategoryController.text.trim()
            : null,
      );

      if (_imagePaths.isNotEmpty && !kIsWeb) {
        listing = await service.uploadImages(listing.id, _imagePaths);
      }

      if (_videoPath != null && !kIsWeb) {
        listing = await service.uploadVideo(listing.id, _videoPath!);
      }

      if (mounted) {
        ref.invalidate(listingsProvider);
        ref.invalidate(myListingsProvider);
        final visible = listing.status == 'ACTIVE';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              visible
                  ? strings.listingPublished
                  : strings.listingModeratedHidden,
            ),
            duration: Duration(seconds: visible ? 3 : 6),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    if (_categories.isEmpty && !_isLoading) {
      _loadCategories();
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.createListing)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: strings.title),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : strings.titleRequired,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: strings.description),
                  validator: (v) => v != null && v.isNotEmpty
                      ? null
                      : strings.descriptionRequired,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: strings.priceLabel),
                  validator: (v) {
                    if (v == null || v.isEmpty) return strings.priceRequired;
                    if (double.tryParse(v) == null) return strings.invalidPrice;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: strings.city),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(labelText: strings.category),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.icon} ${strings.categoryLabel(c.slug)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedCategoryId = v;
                    if (!_isOtherCategory) {
                      _customCategoryController.clear();
                    }
                  }),
                  validator: (v) =>
                      v != null ? null : strings.categoryRequired,
                ),
                if (_isOtherCategory) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customCategoryController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: strings.customCategory,
                      hintText: strings.customCategoryHint,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    validator: (v) {
                      if (!_isOtherCategory) return null;
                      if (v != null && v.trim().length >= 2) return null;
                      return strings.customCategoryRequired;
                    },
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _improveWithAi,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(strings.improveWithAi),
                ),
                const SizedBox(height: 16),
                if (!kIsWeb) ...[
                  OutlinedButton.icon(
                    onPressed: _imagePaths.length >= 5 ? null : _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: Text(strings.addPhotos(_imagePaths.length, 5)),
                  ),
                  const SizedBox(height: 12),
                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePaths[index]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(
                                  () => _imagePaths.removeAt(index),
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
                      if (_videoPath != null) {
                        setState(() => _videoPath = null);
                      } else {
                        _pickVideo();
                      }
                    },
                    icon: Icon(
                      _videoPath != null
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                    ),
                    label: Text(
                      _videoPath != null
                          ? strings.removeVideo
                          : strings.addVideo,
                    ),
                  ),
                  if (_videoPath != null)
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
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(strings.publish),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
