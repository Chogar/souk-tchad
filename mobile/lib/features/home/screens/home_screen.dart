import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/image_search_result.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/utils/search_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/image_search_prep.dart';
import '../../listings/widgets/listing_card.dart';
import '../providers/categories_provider.dart';
import '../providers/listings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _photoSearching = false;
  String? _photoSearchStatus;
  Timer? _searchDebounce;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  ListingsFilter get _filter =>
      ListingsFilter(categoryId: _selectedCategoryId, search: _searchQuery);

  @override
  void initState() {
    super.initState();
    // Le splash charge déjà le catalogue ; pas de refresh ici (évite les boucles).
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _applySearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    setState(() => _searchQuery = query);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategoryId = null;
    });
  }

  Future<void> _showManualSearchDialog({String? infoMessage}) async {
    final strings = ref.read(stringsProvider);
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.manualSearchTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (infoMessage != null) ...[
              Text(
                infoMessage,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.manualSearchHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(strings.search),
          ),
        ],
      ),
    );
    controller.dispose();

    if (query == null || query.isEmpty || !mounted) return;

    _searchDebounce?.cancel();
    _searchController.text = query;
    setState(() {
      _searchQuery = query;
      _selectedCategoryId = null;
    });
    ref.invalidate(listingsProvider(_filter));
  }

  Future<void> _searchByPhoto() async {
    if (kIsWeb) return;

    final strings = ref.read(stringsProvider);
    if (ref.read(authStateProvider).value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.loginRequired)),
      );
      context.go('/login?redirect=${Uri.encodeComponent('/create-listing')}');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(strings.takePhoto),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(strings.chooseFromGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'camera_access_denied' ||
                    e.code == 'photo_access_denied'
                ? strings.photoPermissionDenied
                : '${strings.photoSearchError} : ${e.message ?? e.code}',
          ),
        ),
      );
      return;
    }

    if (picked == null || !mounted) return;

    setState(() {
      _photoSearching = true;
      _photoSearchStatus = strings.preparingPhoto;
    });
    try {
      final service = ref.read(listingsServiceProvider);
      final listingsFuture = service.getListings();
      final categoriesFuture = ref.read(categoriesProvider.future);

      final preparedBytes = await prepareImageForSearch(picked);
      if (!mounted) return;

      setState(() => _photoSearchStatus = strings.sendingPhoto);
      final result = await ref.read(aiServiceProvider).searchByImage(
            picked,
            preparedBytes: preparedBytes,
          );
      if (!mounted) return;

      setState(() => _photoSearchStatus = strings.matchingListings);
      final categories = await categoriesFuture;
      final allListings = await listingsFuture;
      final resolved = _resolvePhotoSearchLocal(
        allListings: allListings,
        result: result,
        categories: categories,
      );
      if (!mounted) return;

      _searchDebounce?.cancel();
      _searchController.text = resolved.searchText;
      setState(() {
        _searchQuery = resolved.searchText;
        _selectedCategoryId = resolved.categoryId;
      });
      ref.invalidate(listingsProvider(_filter));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolved.matchCount > 0
                ? strings.photoSearchDone(resolved.searchText)
                : strings.photoSearchNoMatch(resolved.searchText),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = apiErrorMessage(e, strings);
      final geminiMissing = message.toLowerCase().contains('gemini');

      if (geminiMissing) {
        await _showManualSearchDialog(
          infoMessage: strings.geminiNotConfigured,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.photoSearchError} : $message'),
            action: SnackBarAction(
              label: strings.manualSearchAction,
              onPressed: () => _showManualSearchDialog(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _photoSearching = false;
          _photoSearchStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final strings = ref.watch(stringsProvider);
    final listingsAsync = ref.watch(listingsProvider(_filter));
    final api = ref.watch(apiServiceProvider);
    final screen = MediaQuery.sizeOf(context);
    final sideInset = AppBreakpoints.pageHorizontalInset(screen.width);
    final gridSize = AppBreakpoints.contentSize(screen);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: strings.profile,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => refreshListingsCatalog(ref),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(sideInset, 16, sideInset, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null)
                          Text(
                            strings.hello(user.name),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: 12),
                        _SearchBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hint: strings.searchHint,
                          searchLabel: strings.search,
                          photoTooltip: strings.searchByPhoto,
                          photoSearching: _photoSearching,
                          onChanged: (value) {
                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(
                              const Duration(milliseconds: 450),
                              () {
                                if (!mounted) return;
                                setState(() => _searchQuery = value.trim());
                              },
                            );
                          },
                          onSubmitted: _applySearch,
                          onSearchTap: () => _applySearch(),
                          onClear: _clearSearch,
                          onPhotoTap: _searchByPhoto,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                listingsAsync.when(
                  data: (listings) {
                    if (listings.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(strings.noListingsFound),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  strings.checkServerConnection,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () =>
                                      refreshListingsCatalog(ref),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(strings.retryLoad),
                                ),
                              ],
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _clearSearch,
                                  child: Text(strings.search),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(sideInset, 4, sideInset, 88),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              AppBreakpoints.listingCrossAxisCount(gridSize),
                          childAspectRatio:
                              AppBreakpoints.listingChildAspectRatio(gridSize),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ListingCard(
                            listing: listings[index],
                            api: api,
                            layout: ListingCardLayout.grid,
                          ),
                          childCount: listings.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text(strings.errorWith('$e'))),
                  ),
                ),
              ],
            ),
          ),
          if (_photoSearching)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_photoSearchStatus ?? strings.analyzingPhoto),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoSearchResolution {
  const _PhotoSearchResolution({
    required this.searchText,
    required this.categoryId,
    required this.matchCount,
  });

  final String searchText;
  final String? categoryId;
  final int matchCount;
}

_PhotoSearchResolution _resolvePhotoSearchLocal({
  required List<ListingModel> allListings,
  required ImageSearchResult result,
  required List<CategoryModel> categories,
}) {
  final hintedCategory = _categoryIdFromHint(categories, result.categoryHint);
  final attempts = <MapEntry<String?, String>>[
    MapEntry(hintedCategory, result.searchQuery),
    if (result.primaryTerm != null && result.primaryTerm!.isNotEmpty) ...[
      MapEntry(null, result.primaryTerm!),
      MapEntry(hintedCategory, result.primaryTerm!),
    ],
    MapEntry(null, result.keywords),
  ];

  final seen = <String>{};
  for (final attempt in attempts) {
    final key = '${attempt.key ?? 'all'}|${attempt.value}';
    if (!seen.add(key)) continue;

    var pool = allListings;
    if (attempt.key != null) {
      pool = pool.where((l) => l.category.id == attempt.key).toList();
    }

    final matches = filterAndRankListings(pool, attempt.value);
    if (matches.isNotEmpty) {
      return _PhotoSearchResolution(
        searchText: attempt.value,
        categoryId: attempt.key,
        matchCount: matches.length,
      );
    }
  }

  return _PhotoSearchResolution(
    searchText: result.searchQuery,
    categoryId: hintedCategory,
    matchCount: 0,
  );
}

String? _categoryIdFromHint(List<CategoryModel> categories, String? hint) {
  if (hint == null || hint.isEmpty) return null;
  final normalizedHint = normalizeSearchText(hint);

  for (final category in categories) {
    final slug = normalizeSearchText(category.slug);
    final name = normalizeSearchText(category.name);
    if (slug.contains(normalizedHint) ||
        normalizedHint.contains(slug) ||
        name.contains(normalizedHint) ||
        normalizedHint.contains(name.split(' ').first)) {
      return category.id;
    }
  }
  return null;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.searchLabel,
    required this.photoTooltip,
    required this.photoSearching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearchTap,
    required this.onClear,
    required this.onPhotoTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String searchLabel;
  final String photoTooltip;
  final bool photoSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;
  final VoidCallback onClear;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: onClear,
                            )
                          : null,
                    ),
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: photoTooltip,
              child: Material(
                color: AppColors.accentGold.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: photoSearching ? null : onPhotoTap,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: photoSearching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.photo_camera_outlined,
                            color: AppColors.primaryBlue,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: onSearchTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.search, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
