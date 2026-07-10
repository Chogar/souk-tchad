import 'package:flutter/material.dart';

/// Affiche une photo d'annonce **entière** dans son cadre (jamais rognée).
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({
    super.key,
    required this.url,
    this.backgroundColor,
    this.error,
  });

  final String? url;
  final Color? backgroundColor;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFF3F3F3);
    final fallback = error ??
        ColoredBox(
          color: bg,
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return ColoredBox(color: bg, child: fallback);
        }

        if (url == null || url!.isEmpty) {
          return SizedBox(width: w, height: h, child: fallback);
        }

        return ColoredBox(
          color: bg,
          child: SizedBox(
            width: w,
            height: h,
            child: Image.network(
              url!,
              width: w,
              height: h,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, error, stackTrace) => fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: bg,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
