import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/models/listing_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/currency_format.dart';
import '../widgets/listing_actions_bar.dart';
import '../widgets/listing_photo.dart';

final listingDetailProvider =
    FutureProvider.family<ListingModel, String>((ref, id) async {
  return ref.read(listingsServiceProvider).getListing(id);
});

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final _pageController = PageController();
  int _mediaIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));
    final api = ref.watch(apiServiceProvider);
    final strings = ref.watch(stringsProvider);
    final dateFormat = DateFormat('dd/MM/yyyy', strings.dateLocale);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(strings.listingDetail),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: listingAsync.maybeWhen(
        data: (listing) => ListingActionsBar(
          listingId: listing.id,
          sellerId: listing.user.id,
          sellerPhone: listing.user.phone,
        ),
        orElse: () => null,
      ),
      body: listingAsync.when(
        data: (listing) {
          final sideInset =
              AppBreakpoints.pageHorizontalInset(MediaQuery.sizeOf(context).width);
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 88),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.pageMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MediaGallery(
                      listing: listing,
                      api: api,
                      pageController: _pageController,
                      mediaIndex: _mediaIndex,
                      onPageChanged: (i) => setState(() => _mediaIndex = i),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listing.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    CurrencyFormat.format(
                                      listing.price,
                                      strings.locale,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.accentRed,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _TagChip(
                                    icon: '📍',
                                    label: listing.city,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.description_outlined,
                                        size: 18,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        strings.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    listing.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryBlue
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      listing.user.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          strings.seller,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          listing.user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          strings.publishedOn(
                                            dateFormat
                                                .format(listing.createdAt),
                                          ),
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(strings.errorWith(apiErrorMessage(e, strings))),
        ),
      ),
    );
  }
}

class _MediaGallery extends StatefulWidget {
  const _MediaGallery({
    required this.listing,
    required this.api,
    required this.pageController,
    required this.mediaIndex,
    required this.onPageChanged,
  });

  final ListingModel listing;
  final ApiService api;
  final PageController pageController;
  final int mediaIndex;
  final ValueChanged<int> onPageChanged;

  @override
  State<_MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<_MediaGallery> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  bool get _hasVideo => widget.listing.videos.isNotEmpty;

  int get _itemCount {
    final imageCount = widget.listing.images.length;
    if (imageCount == 0 && !_hasVideo) return 0;
    return imageCount + (_hasVideo ? 1 : 0);
  }

  bool _isVideoPage(int index) =>
      _hasVideo && index == widget.listing.images.length;

  @override
  void initState() {
    super.initState();
    if (_isVideoPage(widget.mediaIndex)) {
      _loadVideo(widget.mediaIndex);
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _videoReady = false;
  }

  Future<void> _loadVideo(int index) async {
    if (!_isVideoPage(index)) return;
    _disposeVideo();
    final url = widget.api.mediaUrl(widget.listing.videos.first);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      if (mounted && _videoController == controller) {
        setState(() => _videoReady = true);
      }
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  void _handlePageChanged(int index) {
    if (_isVideoPage(widget.mediaIndex)) {
      _videoController?.pause();
    }
    widget.onPageChanged(index);
    if (_isVideoPage(index)) {
      _loadVideo(index);
    } else {
      _disposeVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) {
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final galleryWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final galleryHeight = (galleryWidth * 0.85).clamp(300.0, 480.0);

        return Stack(
          children: [
            SizedBox(
              height: galleryHeight,
              width: double.infinity,
              child: PageView.builder(
                controller: widget.pageController,
                itemCount: _itemCount,
                onPageChanged: _handlePageChanged,
                itemBuilder: (context, index) {
                  if (_isVideoPage(index)) {
                    return _buildVideoSlide();
                  }
                  return ListingPhoto(
                    url: widget.api.mediaUrl(widget.listing.images[index]),
                    error: Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_itemCount > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryNavButton(
                    icon: Icons.chevron_left,
                    enabled: widget.mediaIndex > 0,
                    onTap: () => _goToPage(widget.mediaIndex - 1),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryNavButton(
                    icon: Icons.chevron_right,
                    enabled: widget.mediaIndex < _itemCount - 1,
                    onTap: () => _goToPage(widget.mediaIndex + 1),
                  ),
                ),
              ),
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _itemCount,
                    (i) => Container(
                      width: i == widget.mediaIndex ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == widget.mediaIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 56,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${widget.mediaIndex + 1}/$_itemCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
            if (_isVideoPage(widget.mediaIndex))
              Positioned(
                top: MediaQuery.paddingOf(context).top + 56,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Vidéo',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _itemCount) return;
    widget.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildVideoSlide() {
    final controller = _videoController;
    if (controller == null || !_videoReady) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ColoredBox(color: Colors.black),
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        if (!controller.value.isPlaying)
          IconButton.filled(
            iconSize: 56,
            onPressed: () => setState(() => controller.play()),
            icon: const Icon(Icons.play_arrow),
          ),
        Positioned(
          bottom: 40,
          right: 16,
          child: IconButton.filled(
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  const _GalleryNavButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: enabled ? 0.45 : 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.45),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
