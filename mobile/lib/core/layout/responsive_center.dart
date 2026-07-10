import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// Centers [child] and constrains its width on tablet/desktop.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final limit = maxWidth ?? AppBreakpoints.formMaxWidth(width);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: limit),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Thumbnail for a picked image via bytes (works on web + mobile).
class PickedImageThumb extends StatelessWidget {
  const PickedImageThumb({
    super.key,
    required this.bytesFuture,
    this.size = 80,
  });

  final Future<Uint8List> bytesFuture;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: bytesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
        );
      },
    );
  }
}
