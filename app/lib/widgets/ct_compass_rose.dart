import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

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

class _CtCompassRosePainter extends CustomPainter {
  _CtCompassRosePainter({
    required this.armColor,
    required this.ringColor,
    required this.medallionColor,
    required this.medallionCoreColor,
  });

  final Color armColor;
  final Color ringColor;
  final Color medallionColor;
  final Color medallionCoreColor;

  static const double _cardinalArmThickness = 2.0;
  static const double _cardinalArmOpacity = 0.8;
  static const double _diagonalArmThickness = 1.5;
  static const double _diagonalArmOpacity = 0.45;
  static const double _diagonalArmLengthRatio = 0.6;
  static const double _ringDiameterRatio = 0.75;
  static const double _ringOpacity = 0.35;
  static const double _ringStrokeWidth = 1.0;
  static const double _medallionDiameterRatio = 0.25;
  static const double _medallionInnerDiameterRatio = 0.0833;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) {
      return;
    }
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    _paintCardinalArms(canvas, size, cx, cy, side);
    _paintDiagonalArms(canvas, cx, cy, side);
    _paintRing(canvas, cx, cy, side);
    _paintMedallion(canvas, cx, cy, side);
  }

  void _paintCardinalArms(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double side,
  ) {
    final Paint paint = Paint()
      ..color = armColor.withValues(alpha: _cardinalArmOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        cx - _cardinalArmThickness / 2,
        cy - side / 2,
        _cardinalArmThickness,
        side,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cx - side / 2,
        cy - _cardinalArmThickness / 2,
        side,
        _cardinalArmThickness,
      ),
      paint,
    );
  }

  void _paintDiagonalArms(Canvas canvas, double cx, double cy, double side) {
    final Paint paint = Paint()
      ..color = armColor.withValues(alpha: _diagonalArmOpacity)
      ..style = PaintingStyle.fill;
    final double length = side * _diagonalArmLengthRatio;
    final Rect armRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: _diagonalArmThickness,
      height: length,
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-cx, -cy);
    canvas.drawRect(armRect, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-cx, -cy);
    canvas.drawRect(armRect, paint);
    canvas.restore();
  }

  void _paintRing(Canvas canvas, double cx, double cy, double side) {
    final double radius = (side * _ringDiameterRatio) / 2;
    final Paint paint = Paint()
      ..color = ringColor.withValues(alpha: _ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStrokeWidth;
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  void _paintMedallion(Canvas canvas, double cx, double cy, double side) {
    final double outerRadius = (side * _medallionDiameterRatio) / 2;
    final Paint outerPaint = Paint()
      ..color = medallionColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), outerRadius, outerPaint);

    final double innerRadius = (side * _medallionInnerDiameterRatio) / 2;
    if (innerRadius > 0) {
      final Paint innerPaint = Paint()
        ..color = medallionCoreColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CtCompassRosePainter oldDelegate) {
    return oldDelegate.armColor != armColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.medallionColor != medallionColor ||
        oldDelegate.medallionCoreColor != medallionCoreColor;
  }
}

/// Internal helper exposed for tests: returns the documented opacity for the
/// cardinal arms (north/south/east/west crossbar of the rose).
@visibleForTesting
double get ctCompassRoseCardinalArmOpacityForTesting =>
    _CtCompassRosePainter._cardinalArmOpacity;

/// Internal helper exposed for tests: returns the documented opacity for the
/// diagonal `±45°` arms.
@visibleForTesting
double get ctCompassRoseDiagonalArmOpacityForTesting =>
    _CtCompassRosePainter._diagonalArmOpacity;

/// Internal helper exposed for tests: returns the documented opacity for the
/// outer decorative ring.
@visibleForTesting
double get ctCompassRoseRingOpacityForTesting =>
    _CtCompassRosePainter._ringOpacity;

/// Internal helper exposed for tests: returns the ring diameter for a given
/// square side length (the painter scales to the smaller of width/height).
@visibleForTesting
double ctCompassRoseRingDiameterForTesting(double side) =>
    side * _CtCompassRosePainter._ringDiameterRatio;

/// Internal helper exposed for tests: returns the outer medallion diameter
/// for a given square side length.
@visibleForTesting
double ctCompassRoseMedallionDiameterForTesting(double side) =>
    side * _CtCompassRosePainter._medallionDiameterRatio;

/// Internal helper exposed for tests: returns the inner (engraved pinhole)
/// medallion diameter for a given square side length.
@visibleForTesting
double ctCompassRoseMedallionInnerDiameterForTesting(double side) =>
    side * _CtCompassRosePainter._medallionInnerDiameterRatio;

/// Internal helper exposed for tests: returns the diagonal-arm length for a
/// given square side length.
@visibleForTesting
double ctCompassRoseDiagonalArmLengthForTesting(double side) =>
    side * _CtCompassRosePainter._diagonalArmLengthRatio;
