import 'package:flutter/widgets.dart';

/// Breakpoints for phone / tablet / desktop layouts.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium;

  static bool ofCompact(BuildContext context) =>
      isCompact(MediaQuery.sizeOf(context).width);

  static bool ofExpanded(BuildContext context) =>
      isExpanded(MediaQuery.sizeOf(context).width);

  /// Colonnes grille : 2 téléphone, 3 tablette, 6 desktop.
  static int listingCrossAxisCount(Size size) {
    if (size.width < compact) return 2;
    if (size.width < medium) return 3;
    if (size.width < expanded) return 4;
    return 6;
  }

  static bool isLandscape(Size size) => size.width > size.height;

  /// Admin paiements : toujours 4 colonnes (portrait et paysage).
  static int adminPaymentsCrossAxisCount(Size size) => 4;

  static double adminPaymentsChildAspectRatio(Size size) {
    const horizontalPadding = 32.0;
    const crossSpacing = 36.0; // 3 × 12
    final cellWidth = (size.width - horizontalPadding - crossSpacing) / 4;
    final targetHeight = size.width < compact
        ? 200.0
        : size.width < medium
            ? 190.0
            : 175.0;
    return (cellWidth / targetHeight).clamp(0.38, 0.78);
  }

  /// Admin annonces : 6 colonnes en paysage large ou écran ≥ 1200 px.
  static int adminListingsCrossAxisCount(Size size) {
    if (size.width >= expanded) return 6;
    if (isLandscape(size) && size.width >= medium) return 6;
    if (size.width < compact) return 1;
    if (size.width < medium) return 2;
    return 3;
  }

  static double adminListingsChildAspectRatio(Size size) {
    final cols = adminListingsCrossAxisCount(size);
    if (cols >= 6) return 0.78;
    if (cols >= 3) return 0.9;
    if (cols == 2) return 1.05;
    return 1.35;
  }

  /// Image + titre + prix + meta.
  static double listingChildAspectRatio(Size size) {
    if (size.width < compact) return 0.68;
    if (size.width < medium) return 0.65;
    return 0.62;
  }

  static double formMaxWidth(double width) {
    if (width >= medium) return 640;
    if (width >= compact) return 520;
    return double.infinity;
  }

  /// Centered content with side gutters (wide enough for 6 columns).
  static const double pageMaxWidth = 1280;

  static double pageHorizontalInset(double screenWidth) {
    if (screenWidth <= pageMaxWidth) {
      return screenWidth < compact ? 12 : 24;
    }
    return (screenWidth - pageMaxWidth) / 2;
  }

  /// Size used for grid columns = content area, not full window.
  static Size contentSize(Size screen) {
    final w = screen.width > pageMaxWidth ? pageMaxWidth : screen.width;
    return Size(w, screen.height);
  }
}
