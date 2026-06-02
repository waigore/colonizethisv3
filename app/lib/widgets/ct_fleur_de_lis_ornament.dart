import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Stylized fleur-de-lis ornament used to flank the main-menu title in the
/// dark editorial-monocle theme.
///
/// Implements `Refs #2860` S4 + § *CtFleurDeLisOrnament visual contract*.
/// The widget is a self-painted decorative glyph (no asset) sized to a
/// `24 x 32` aspect viewBox; the painter scales the same primitives to fit
/// the widget's box without distorting the aspect ratio. All colors resolve
/// from [EditorialMonoclePalette] tokens (issue #2858) — no hard-coded hex
/// literals.
///
/// Visual layout (mirrors the inline `<svg class="title-flank">` block in
/// `SPEC/ui/mockups/SHEL10002-main-menu.html`):
///
/// * **Top petal** — vertical ellipse centered on the upper third
///   (`(12, 6)`, radii `3 x 5`).
/// * **Left side petal** — squat ellipse offset left (`(5, 10)`, radii
///   `4 x 3.5`).
/// * **Right side petal** — mirror of the left petal (`(19, 10)`, radii
///   `4 x 3.5`).
/// * **Cross bar** — thin horizontal band linking the three petals
///   (`(7, 14)` of size `10 x 2.5`, rounded radius `1`).
/// * **Stem** — tall rounded rectangle running from the bar down through
///   the lower half (`(10.5, 14)` of size `3 x 16`, rounded radius `1.5`).
///
/// Per the mockup all primitives are painted at [_glyphOpacity] alpha so
/// the ornament reads as a muted brass flourish rather than a bold logo.
class CtFleurDeLisOrnament extends StatelessWidget {
  const CtFleurDeLisOrnament({
    super.key,
    this.width = 24,
    this.height = 32,
  });

  /// Outer width of the ornament in logical pixels. The painter preserves
  /// the canonical `3:4` aspect ratio by scaling primitives uniformly to
  /// the smaller of `width / 24` and `height / 32`.
  final double width;

  /// Outer height of the ornament in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CtFleurDeLisOrnamentPainter(
          color: EditorialMonoclePalette.accentDim,
        ),
      ),
    );
  }
}

class _CtFleurDeLisOrnamentPainter extends CustomPainter {
  _CtFleurDeLisOrnamentPainter({required this.color});

  final Color color;

  /// Designed viewBox for the inline SVG primitives.
  static const double _viewBoxWidth = 24;
  static const double _viewBoxHeight = 32;

  /// Brass flourish opacity per the mockup `.title-flank { opacity: 0.6 }`
  /// rule. The widget paints into the canvas with this alpha so it reads as
  /// a muted ornament rather than a bold logo.
  static const double _glyphOpacity = 0.6;

  // Primitive geometry in the 24 x 32 designed viewBox. Values mirror the
  // inline `<svg>` rules in SPEC/ui/mockups/SHEL10002-main-menu.html.
  static const Offset _topPetalCenter = Offset(12, 6);
  static const Size _topPetalRadii = Size(3, 5);
  static const Offset _leftPetalCenter = Offset(5, 10);
  static const Offset _rightPetalCenter = Offset(19, 10);
  static const Size _sidePetalRadii = Size(4, 3.5);
  static const Rect _crossBarRect = Rect.fromLTWH(7, 14, 10, 2.5);
  static const Radius _crossBarRadius = Radius.circular(1);
  static const Rect _stemRect = Rect.fromLTWH(10.5, 14, 3, 16);
  static const Radius _stemRadius = Radius.circular(1.5);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final double scaleX = size.width / _viewBoxWidth;
    final double scaleY = size.height / _viewBoxHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Center the scaled viewBox inside the widget so non-matching aspect
    // ratios pillarbox/letterbox cleanly instead of stretching.
    final double offsetX = (size.width - _viewBoxWidth * scale) / 2;
    final double offsetY = (size.height - _viewBoxHeight * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    final Paint paint = Paint()
      ..color = color.withValues(alpha: _glyphOpacity)
      ..style = PaintingStyle.fill;

    _paintEllipse(canvas, _topPetalCenter, _topPetalRadii, paint);
    _paintEllipse(canvas, _leftPetalCenter, _sidePetalRadii, paint);
    _paintEllipse(canvas, _rightPetalCenter, _sidePetalRadii, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(_crossBarRect, _crossBarRadius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(_stemRect, _stemRadius),
      paint,
    );

    canvas.restore();
  }

  void _paintEllipse(Canvas canvas, Offset center, Size radii, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radii.width * 2,
        height: radii.height * 2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CtFleurDeLisOrnamentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Internal helper exposed for tests: returns the documented glyph opacity
/// (alpha multiplier applied to every primitive painted by the ornament).
@visibleForTesting
double get ctFleurDeLisGlyphOpacityForTesting =>
    _CtFleurDeLisOrnamentPainter._glyphOpacity;

/// Internal helper exposed for tests: returns the canonical SVG viewBox the
/// painter scales its primitives from (`24 x 32`).
@visibleForTesting
Size get ctFleurDeLisViewBoxForTesting => const Size(
  _CtFleurDeLisOrnamentPainter._viewBoxWidth,
  _CtFleurDeLisOrnamentPainter._viewBoxHeight,
);
