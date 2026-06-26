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
import '../utils/delete_listing_helper.dart';
import '../utils/listing_media_picker.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _customCategoryController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  final List<String> _existingImageUrls = [];
  final List<String> _newImagePaths = [];
  String? _existingVideoPath;
  String? _newVideoPath;
  bool _removeVideo = false;
  bool _isLoading = false;
  bool _initialized = false;
  String _listingTitle = '';

  int get _totalImages => _existingImageUrls.length + _newImagePaths.length;

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

  Future<void> _loadData() async {
    final service = ref.read(listingsServiceProvider);
    final api = ref.read(apiServiceProvider);
    final listing = await service.getListing(widget.listingId);
    final categories = await service.getCategories();
    final strings = ref.read(stringsProvider);
    if (!mounted) return;

    setState(() {
      _categories = categories;
      _listingTitle = listing.title;
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _priceController.text = CurrencyFormat.xafToInput(
        listing.price,
        strings.locale,
      ).round().toString();
      _cityController.text = listing.city;
      _selectedCategoryId = listing.category.id;
      _customCategoryController.text = listing.customCategoryName ?? '';
      _existingImageUrls
        ..clear()
        ..addAll(listing.images.map(api.mediaUrl));
      _existingVideoPath =
          listing.videos.isNotEmpty ? listing.videos.first : null;
      _newVideoPath = null;
      _removeVideo = false;
      _initialized = true;
    });
  }

  Future<void> _pickImages() async {
    if (_totalImages >= 5) return;

    final strings = ref.read(stringsProvider);
    final source = await showPhotoSourceSheet(context, strings);
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (file == null || _totalImages >= 5) return;
      final compressed = await _compressImage(file.path, _newImagePaths.length);
      if (compressed != null) {
        setState(() => _newImagePaths.add(compressed));
      }
      return;
    }

    final files = await picker.pickMultiImage(imageQuality: 70);
    if (files.isEmpty) return;

    final compressedPaths = <String>[];
    var index = _newImagePaths.length;
    for (final file in files.take(5 - _totalImages)) {
      final compressed = await _compressImage(file.path, index);
      if (compressed != null) compressedPaths.add(compressed);
      index++;
    }

    setState(() => _newImagePaths.addAll(compressedPaths));
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
    setState(() {
      _newVideoPath = file.path;
      _removeVideo = false;
    });
  }

  bool get _hasVideo =>
      !_removeVideo && (_newVideoPath != null || _existingVideoPath != null);

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

  Future<void> _submit() async {
    final strings = ref.read(stringsProvider);
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(listingsServiceProvider);

      final keptServerPaths = _existingImageUrls
          .map((url) {
            if (url.startsWith('http')) {
              final uri = Uri.parse(url);
              return uri.path;
            }
            return url;
          })
          .toList();

      var listing = await service.updateListing(
        widget.listingId,
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
            : '',
        images: keptServerPaths,
      );

      if (_newImagePaths.isNotEmpty && !kIsWeb) {
        listing = await service.uploadImages(widget.listingId, _newImagePaths);
      }

      if (_removeVideo) {
        listing = await service.updateListing(
          widget.listingId,
          videos: [],
        );
      }

      if (_newVideoPath != null && !kIsWeb) {
        listing = await service.uploadVideo(widget.listingId, _newVideoPath!);
      }

      ref.invalidate(myListingsProvider);
      ref.invalidate(listingsProvider);

      if (mounted) {
        final visible = listing.status == 'ACTIVE';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              visible
                  ? strings.listingUpdatedSuccess
                  : strings.listingUpdatedHidden,
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.errorWith(apiErrorMessage(e, strings)))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _loadData();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.editListing)),
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
                const SizedBox(height: 16),
                if (!kIsWeb) ...[
                  OutlinedButton.icon(
                    onPressed: _totalImages >= 5 ? null : _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: Text(strings.addPhotos(_totalImages, 5)),
                  ),
                  const SizedBox(height: 12),
                  if (_totalImages > 0)
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _totalImages,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isExisting = index < _existingImageUrls.length;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isExisting
                                    ? Image.network(
                                        _existingImageUrls[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Image.file(
                                        File(_newImagePaths[
                                            index - _existingImageUrls.length]),
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
                                  onPressed: () => setState(() {
                                    if (isExisting) {
                                      _existingImageUrls.removeAt(index);
                                    } else {
                                      _newImagePaths.removeAt(
                                        index - _existingImageUrls.length,
                                      );
                                    }
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_hasVideo) {
                        setState(() {
                          _removeVideo = true;
                          _newVideoPath = null;
                          _existingVideoPath = null;
                        });
                      } else {
                        _pickVideo();
                      }
                    },
                    icon: Icon(
                      _hasVideo
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                    ),
                    label: Text(
                      _hasVideo ? strings.removeVideo : strings.addVideo,
                    ),
                  ),
                  if (_hasVideo)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.videoAttached,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (_newVideoPath == null &&
                              _existingVideoPath != null)
                            TextButton(
                              onPressed: _pickVideo,
                              child: Text(strings.replaceVideo),
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
                      : Text(strings.save),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => deleteListingWithConfirmation(
                            context: context,
                            ref: ref,
                            listingId: widget.listingId,
                            listingTitle: _listingTitle.isNotEmpty
                                ? _listingTitle
                                : _titleController.text,
                            onSuccess: () {
                              if (context.mounted) context.pop();
                            },
                          ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.deleteListing),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
