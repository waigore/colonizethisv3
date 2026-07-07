import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

part 'ct_brass_divider_painter.dart';

/// Ornate brass divider for the dark editorial-monocle theme.
///
/// Implements `Refs #2859` R7 + § *CtBrassDivider visual contract*. The widget
/// has a fixed 8px intrinsic height (matching its 8x8 diamond centerpiece)
/// and stretches horizontally to fill its parent's max width. All colors
/// resolve from [EditorialMonoclePalette] tokens (issue #2858); no hard-coded
/// hex literals.
///
/// Visual layout (single source of truth — `SPEC/ui/pixel-art-ui-catalog.md`):
///
/// * 1px-tall horizontal gradient line centered vertically across the divider
///   width. Linear gradient: transparent → `--accent-dim` at the midpoint →
///   transparent.
/// * 8x8 diamond (square rotated 45 degrees) centered horizontally, fill
///   `--accent`, 1px outline `--accent-bright`. The diamond paints on top of
///   the gradient line at the midpoint.
/// * Three round dots (`2px` radius, `4x4` bounding box) on each side of the
///   diamond, colored `--accent-dim`. Dot centers are spaced 4px apart along
///   the horizontal centerline; the first dot on each side is centered 6px
///   outward from the nearest diamond edge.
class CtBrassDivider extends StatelessWidget {
  const CtBrassDivider({super.key});

  /// Fixed divider height matching the 8x8 diamond centerpiece.
  static const double height = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CtBrassDividerPainter(
          lineColor: EditorialMonoclePalette.accentDim,
          diamondFill: EditorialMonoclePalette.accent,
          diamondOutline: EditorialMonoclePalette.accentBright,
          dotColor: EditorialMonoclePalette.accentDim,
        ),
      ),
    );
  }
}

/// Internal helper exposed for tests: returns the centerline x offsets of
/// the three dots on the right side of the diamond, given a divider width.
@visibleForTesting
List<double> ctBrassDividerRightDotCentersForTesting(double dividerWidth) {
  final double centerX = dividerWidth / 2;
  return List<double>.generate(
    _CtBrassDividerPainter._dotsPerSide,
    (i) =>
        centerX +
        _CtBrassDividerPainter._diamondHalfDiagonal +
        _CtBrassDividerPainter._firstDotOffsetFromDiamond +
        _CtBrassDividerPainter._dotSpacing * i,
  );
}

/// Internal helper exposed for tests: returns the diamond bounding box for a
/// given divider width and height.
@visibleForTesting
Rect ctBrassDividerDiamondBoundsForTesting(double dividerWidth) {
  final double centerX = dividerWidth / 2;
  const double half = _CtBrassDividerPainter._diamondHalfDiagonal;
  const double centerY = CtBrassDivider.height / 2;
  return Rect.fromLTWH(centerX - half, centerY - half, half * 2, half * 2);
}

/// Internal helper exposed for tests: minimum width required for the divider
/// to render every documented element without overlap (diamond + 3 dots per
/// side + an exterior margin so the outermost dot is fully drawn).
@visibleForTesting
double get ctBrassDividerMinWidthForTesting {
  const double half = _CtBrassDividerPainter._diamondHalfDiagonal;
  const double lastDotOffset =
      half +
      _CtBrassDividerPainter._firstDotOffsetFromDiamond +
      _CtBrassDividerPainter._dotSpacing *
          (_CtBrassDividerPainter._dotsPerSide - 1);
  return 2 * (lastDotOffset + _CtBrassDividerPainter._dotRadius);
}
