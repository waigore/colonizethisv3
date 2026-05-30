import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';

/// Dark editorial-monocle backdrop for the in-game map stack.
///
/// Paints the mockup `.map-area` + `.map-grid` treatment from
/// `SPEC/ui/mockups/GAME10001-game-screen.html`: a `--bg-deep` base with
/// subtle radial washes and a 48 dp grid at low opacity. Issue #2861 R3.
///
/// The widget is intentionally non-interactive (`IgnorePointer`) and is
/// mounted behind [CtRegionMap] inside [GameMapArea].
class GameMapAreaBackground extends StatelessWidget {
  const GameMapAreaBackground({super.key});

  /// Stable key for widget / integration tests.
  static const Key surfaceKey = Key('game_map_area_background');

  /// Grid cell size in logical pixels (mockup `.map-grid background-size`).
  static const double gridCellSize = 48;

  /// Opacity applied to the grid overlay layer (mockup `.map-grid opacity`).
  static const double gridOpacity = 0.6;

  /// Grid line colour: mockup `oklch(40% 0.02 55 / 0.08)` — approximated
  /// from [EditorialMonoclePalette.border] at 8% alpha.
  static Color get gridLineColor =>
      EditorialMonoclePalette.border.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            key: surfaceKey,
            decoration: BoxDecoration(
              color: EditorialMonoclePalette.bgDeep,
              gradient: RadialGradient(
                center: const Alignment(-0.4, 0.2),
                radius: 0.85,
                colors: <Color>[
                  oklchApprox(0.25, 0.03, 110, alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const <double>[0.0, 0.5],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.4, -0.4),
                radius: 0.85,
                colors: <Color>[
                  oklchApprox(0.22, 0.04, 200, alpha: 0.25),
                  Colors.transparent,
                ],
                stops: const <double>[0.0, 0.5],
              ),
            ),
          ),
          Opacity(
            opacity: gridOpacity,
            child: CustomPaint(
              painter: _MapGridPainter(
                lineColor: gridLineColor,
                cellSize: gridCellSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lightweight OKLCH → sRGB helper for the two radial wash tokens that
  /// are not part of the canonical editorial-monocle table.
  static Color oklchApprox(
    double lightness,
    double chroma,
    double hueDegrees, {
    required double alpha,
  }) {
    return oklchToColor(
      OklchToken(lightness, chroma, hueDegrees),
    ).withValues(alpha: alpha);
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.lineColor, required this.cellSize});

  final Color lineColor;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.cellSize != cellSize;
  }
}
