import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

part 'ct_compass_rose_painter.dart';

/// Ornate 8-arm compass rose emblem for the dark editorial-monocle theme.
///
/// Implements `Refs #2860` S1 + § *CtCompassRose visual contract*. The widget
/// is a self-painted decorative emblem (no asset) used in the main-menu
/// title region above the "ColonizeThis" headline. It scales to fill the
/// smaller of the two parent constraints so the rose stays circular.
///
/// All colors resolve from [EditorialMonoclePalette] tokens (issue #2858) —
/// no hard-coded hex literals.
///
/// Visual layout (mirrors `SPEC/ui/mockups/SHEL10002-main-menu.html`
/// `.compass-rose` rule block):
///
/// * **Cardinal arms** — two crossing lines: a 2px-wide vertical line
///   spanning the full height, and a 2px-tall horizontal line spanning the
///   full width. Both rendered at [EditorialMonoclePalette.accent] with
///   `0.8` alpha.
/// * **Diagonal arms** — two 1.5px-wide bars rotated `±45°` around the
///   widget center, length `60%` of the widget side, painted in
///   [EditorialMonoclePalette.accent] with `0.45` alpha.
/// * **Outer ring** — a 1px stroked circle whose diameter is
///   [_ringDiameterRatio] of the widget side, painted in
///   [EditorialMonoclePalette.accent] at `0.35` alpha.
/// * **Center medallion** — a filled circle of diameter
///   [_medallionDiameterRatio] of the widget side, painted in
///   [EditorialMonoclePalette.accent]; a small inner circle of diameter
///   [_medallionInnerDiameterRatio] cut against
///   [EditorialMonoclePalette.bgDeep] simulates the engraved pinhole shown
///   in the mockup.
class CtCompassRose extends StatelessWidget {
  const CtCompassRose({super.key, this.size = 48});

  /// Outer side length of the rose (square). The painter fits the rose
  /// to a square of this side. Default matches the mockup's mid-viewport
  /// `clamp(32px, 6vw, 48px)` typical desktop value.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CtCompassRosePainter(
          armColor: EditorialMonoclePalette.accent,
          ringColor: EditorialMonoclePalette.accent,
          medallionColor: EditorialMonoclePalette.accent,
          medallionCoreColor: EditorialMonoclePalette.bgDeep,
        ),
      ),
    );
  }
}
