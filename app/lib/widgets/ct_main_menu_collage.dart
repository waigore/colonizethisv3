import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Decorative dark SVG-collage background for the editorial-monocle main
/// menu (`SHEL10002`).
///
/// Implements `Refs #2860` S2 + `SPEC/ui/main-menu.md` § *Background*. The
/// widget is a self-painted decorative collage (no asset) used as the
/// fixed-position background of the `pixelArt` variant of `CtMainMenu`.
/// All primitives are painted via Flutter `CustomPainter`; **no external
/// SVG runtime asset is required**.
///
/// The painter mirrors the inline `<svg class="collage-svg">` block of
/// `SPEC/ui/mockups/SHEL10002-main-menu.html` (viewBox `1920 x 1080`,
/// `preserveAspectRatio="xMidYMid meet"`). Glyphs scale uniformly to fit
/// the smaller of the two parent dimensions and are centered with
/// pillarbox/letterbox margins so the collage never stretches.
///
/// All colors resolve from [EditorialMonoclePalette] tokens (issue #2858):
///
/// * `--accent` is the `currentColor` for every SVG primitive (set on the
///   `.collage-svg` root in the mockup).
/// * `--bg` is the canvas background that the collage sits over (painted
///   by the parent `Scaffold`).
///
/// Glyph families (mockup `<svg>` order):
///
/// 1. Dashed trade-route arcs (5 quadratic curves at `0.40` group alpha).
/// 2. Navigation-star waypoints (4 diamond + ring pairs at `0.45`).
/// 3. Telescope (top-left, rotated `-14°`, `0.55`).
/// 4. Spyglass (top-left smaller, rotated `-6°`, `0.50`).
/// 5. Crossed muskets (top-right, rotated `+32°` and `-36°`, `0.55`).
/// 6. Powder horn (top-right, rotated `-40°`, `0.50`).
/// 7. Sextant (mid-left, `0.55`).
/// 8. Hourglass (mid-left lower, `0.55`).
/// 9. Anchor (bottom-left, `0.55`).
/// 10. Soldier silhouette (mid-right, `0.55`).
/// 11. Ship's wheel (mid-right, `0.55`).
/// 12. Cannon with cannonballs (bottom-right, `0.55`).
/// 13. Layered wave bands (bottom, `0.50`).
///
/// A final group opacity of [_collageOpacity] (`0.8` per the
/// `.collage-svg { opacity }` rule) is layered over every primitive so the
/// collage reads as a muted background, not a foreground illustration.
class CtMainMenuCollage extends StatelessWidget {
  const CtMainMenuCollage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _CtMainMenuCollagePainter(
          glyphColor: EditorialMonoclePalette.accent,
        ),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _CtMainMenuCollagePainter extends CustomPainter {
  _CtMainMenuCollagePainter({required this.glyphColor});

  final Color glyphColor;

  // Designed viewBox for the inline collage SVG.
  static const double _viewBoxWidth = 1920;
  static const double _viewBoxHeight = 1080;

  // Final group opacity from the `.collage-svg { opacity: 0.8 }` rule.
  // The painter layers this on top of each glyph's per-group alpha so the
  // total alpha matches `groupAlpha * 0.8` exactly.
  static const double _collageOpacity = 0.8;

  // Per-group opacity multipliers as documented in the mockup `<g opacity>`
  // attributes. Exposed as named constants so tests can pin the values
  // against the mockup without parsing the inline SVG.
  static const double _tradeRoutesOpacity = 0.40;
  static const double _waypointsOpacity = 0.45;
  static const double _telescopeOpacity = 0.55;
  static const double _spyglassOpacity = 0.50;
  static const double _musketsOpacity = 0.55;
  static const double _powderHornOpacity = 0.50;
  static const double _sextantOpacity = 0.55;
  static const double _hourglassOpacity = 0.55;
  static const double _anchorOpacity = 0.55;
  static const double _soldierOpacity = 0.55;
  static const double _shipsWheelOpacity = 0.55;
  static const double _cannonOpacity = 0.55;
  static const double _wavesOpacity = 0.50;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    // preserveAspectRatio="xMidYMid meet" — scale uniformly to fit the
    // smaller axis and center.
    final double scaleX = size.width / _viewBoxWidth;
    final double scaleY = size.height / _viewBoxHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;
    final double offsetX = (size.width - _viewBoxWidth * scale) / 2;
    final double offsetY = (size.height - _viewBoxHeight * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // Save layer for the final collage alpha so every glyph receives the
    // 0.8 multiplier exactly once, matching the `.collage-svg { opacity }`
    // CSS rule.
    const Rect layerBounds = Rect.fromLTWH(
      0,
      0,
      _viewBoxWidth,
      _viewBoxHeight,
    );
    final Paint layerPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: _collageOpacity);
    canvas.saveLayer(layerBounds, layerPaint);

    _paintTradeRoutes(canvas);
    _paintWaypoints(canvas);
    _paintTelescope(canvas);
    _paintSpyglass(canvas);
    _paintMuskets(canvas);
    _paintPowderHorn(canvas);
    _paintSextant(canvas);
    _paintHourglass(canvas);
    _paintAnchor(canvas);
    _paintSoldier(canvas);
    _paintShipsWheel(canvas);
    _paintCannon(canvas);
    _paintWaves(canvas);

    canvas.restore();
    canvas.restore();
  }

  Paint _fill(double groupAlpha, {double glyphAlpha = 1.0}) {
    return Paint()
      ..color = glyphColor.withValues(alpha: groupAlpha * glyphAlpha)
      ..style = PaintingStyle.fill;
  }

  Paint _stroke(
    double groupAlpha,
    double strokeWidth, {
    double glyphAlpha = 1.0,
    StrokeCap cap = StrokeCap.butt,
  }) {
    return Paint()
      ..color = glyphColor.withValues(alpha: groupAlpha * glyphAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = cap;
  }

  void _drawRRect(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    double radius,
    Paint paint,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashLength,
    double gapLength,
  ) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  // ─── Trade routes ─────────────────────────────────────────────────────
  void _paintTradeRoutes(Canvas canvas) {
    final Paint thick = _stroke(_tradeRoutesOpacity, 1.2);
    final Paint thin = _stroke(_tradeRoutesOpacity, 1.0);

    Path quad(double x1, double y1, double cx, double cy, double x2, double y2) {
      return Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(cx, cy, x2, y2);
    }

    _drawDashedPath(canvas, quad(240, 200, 400, 280, 560, 380), thick, 8, 14);
    _drawDashedPath(canvas, quad(560, 380, 620, 480, 500, 620), thick, 8, 14);
    _drawDashedPath(canvas, quad(1560, 160, 1480, 300, 1420, 440), thick, 8, 14);
    _drawDashedPath(canvas, quad(1420, 440, 1500, 580, 1600, 680), thick, 8, 14);
    _drawDashedPath(canvas, quad(300, 780, 380, 680, 500, 600), thin, 6, 12);
  }

  // ─── Navigation stars / waypoints ─────────────────────────────────────
  void _paintWaypoints(Canvas canvas) {
    final Paint fill = _fill(_waypointsOpacity);
    final Paint stroke = _stroke(_waypointsOpacity, 0.8);

    void waypoint(double cx, double cy, double r) {
      final Path diamond = Path()
        ..moveTo(cx - 5, cy - 8)
        ..lineTo(cx + 5, cy + 2)
        ..lineTo(cx - 5, cy + 12)
        ..lineTo(cx - 15, cy + 2)
        ..close();
      canvas.drawPath(diamond, fill);
      canvas.drawCircle(Offset(cx, cy), r, stroke);
    }

    waypoint(560, 380, 14);
    waypoint(500, 620, 11);
    waypoint(1420, 440, 13);
    waypoint(1560, 160, 10);
  }

  // ─── Telescope ────────────────────────────────────────────────────────
  void _paintTelescope(Canvas canvas) {
    canvas.save();
    canvas.translate(140, 120);
    canvas.rotate(_deg(-14));
    final Paint full = _fill(_telescopeOpacity);
    canvas.drawPath(
      _polygon([
        const Offset(0, 14),
        const Offset(190, 24),
        const Offset(190, 28),
        const Offset(0, 18),
      ]),
      full,
    );
    canvas.drawPath(
      _polygon([
        const Offset(185, 22),
        const Offset(220, 20),
        const Offset(220, 32),
        const Offset(185, 30),
      ]),
      full,
    );
    final Paint band = _fill(_telescopeOpacity, glyphAlpha: 0.6);
    _drawRRect(canvas, 50, 16, 7, 18, 2.5, band);
    _drawRRect(canvas, 120, 19, 7, 15, 2.5, band);
    final Paint grip = _fill(_telescopeOpacity, glyphAlpha: 0.5);
    _drawRRect(canvas, 80, 27, 12, 32, 3, grip);
    canvas.restore();
  }

  void _paintSpyglass(Canvas canvas) {
    canvas.save();
    canvas.translate(190, 310);
    canvas.rotate(_deg(-6));
    final Paint full = _fill(_spyglassOpacity);
    canvas.drawPath(
      _polygon([
        const Offset(0, 6),
        const Offset(95, 12),
        const Offset(95, 14),
        const Offset(0, 8),
      ]),
      full,
    );
    canvas.drawPath(
      _polygon([
        const Offset(91, 11),
        const Offset(110, 10),
        const Offset(110, 16),
        const Offset(91, 15),
      ]),
      full,
    );
    final Paint band = _fill(_spyglassOpacity, glyphAlpha: 0.7);
    _drawRRect(canvas, 30, 8, 3.5, 9, 1.5, band);
    _drawRRect(canvas, 60, 10, 3.5, 7, 1.5, band);
    canvas.restore();
  }

  // ─── Crossed muskets + powder horn ────────────────────────────────────
  void _paintMuskets(Canvas canvas) {
    void musket(double tx, double ty, double rotationDeg) {
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(_deg(rotationDeg));
      final Paint barrel = _fill(_musketsOpacity);
      _drawRRect(canvas, 0, 9, 195, 6, 3, barrel);
      final Paint stockHigh = _fill(_musketsOpacity, glyphAlpha: 0.8);
      canvas.drawPath(
        _polygon([
          const Offset(190, 6),
          const Offset(235, 0),
          const Offset(268, 14),
          const Offset(235, 18),
          const Offset(195, 12),
        ]),
        stockHigh,
      );
      canvas.drawPath(
        _polygon([
          const Offset(0, 7),
          const Offset(-12, 12),
          const Offset(0, 17),
        ]),
        stockHigh,
      );
      final Paint hammer = _fill(_musketsOpacity, glyphAlpha: 0.6);
      _drawRRect(canvas, 140, 11, 22, 8, 3, hammer);
      final Paint band = _fill(_musketsOpacity, glyphAlpha: 0.5);
      _drawRRect(canvas, 48, 10, 70, 5, 2.5, band);
      canvas.restore();
    }

    musket(1680, 70, 32);
    musket(1660, 130, -36);
  }

  void _paintPowderHorn(Canvas canvas) {
    canvas.save();
    canvas.translate(1630, 360);
    canvas.rotate(_deg(-40));
    final Paint body = _fill(_powderHornOpacity);
    final Path horn = Path()
      ..moveTo(0, 15)
      ..quadraticBezierTo(20, 0, 60, 10)
      ..quadraticBezierTo(70, 20, 40, 30)
      ..quadraticBezierTo(10, 30, 0, 15)
      ..close();
    canvas.drawPath(horn, body);
    final Paint plug = _fill(_powderHornOpacity, glyphAlpha: 0.8);
    _drawRRect(canvas, -2, 10, 8, 4, 2, plug);
    canvas.restore();
  }

  // ─── Sextant ──────────────────────────────────────────────────────────
  void _paintSextant(Canvas canvas) {
    canvas.save();
    canvas.translate(80, 540);
    // Arc 100,100 from (0,0) to (95,52) — drawn with a quadratic curve
    // approximation good enough for a decorative background glyph.
    final Path arc = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(60, -10, 95, 52);
    canvas.drawPath(
      arc,
      _stroke(_sextantOpacity, 3.5, cap: StrokeCap.round),
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(70, 14),
      _stroke(_sextantOpacity, 2.2),
    );
    final Paint mount = _fill(_sextantOpacity, glyphAlpha: 0.6);
    canvas.save();
    canvas.translate(2, 0);
    canvas.rotate(_deg(-20));
    canvas.translate(-2, 0);
    _drawRRect(canvas, -4, -8, 12, 16, 2.5, mount);
    canvas.restore();
    _drawRRect(canvas, -6, 10, 9, 22, 3.5, mount);
    canvas.restore();
  }

  // ─── Hourglass ────────────────────────────────────────────────────────
  void _paintHourglass(Canvas canvas) {
    canvas.save();
    canvas.translate(130, 710);
    final Paint cap = _fill(_hourglassOpacity, glyphAlpha: 0.8);
    _drawRRect(canvas, 18, 0, 34, 6, 3, cap);
    _drawRRect(canvas, 18, 64, 34, 6, 3, cap);
    final Paint frame = _stroke(_hourglassOpacity, 2, glyphAlpha: 0.6);
    canvas.drawLine(const Offset(0, 3), const Offset(0, 67), frame);
    canvas.drawLine(const Offset(70, 3), const Offset(70, 67), frame);
    final Paint sand = _fill(_hourglassOpacity, glyphAlpha: 0.5);
    canvas.drawPath(
      _polygon([
        const Offset(21, 6),
        const Offset(12, 33),
        const Offset(58, 33),
        const Offset(49, 6),
      ]),
      sand,
    );
    canvas.drawPath(
      _polygon([
        const Offset(21, 64),
        const Offset(12, 37),
        const Offset(58, 37),
        const Offset(49, 64),
      ]),
      sand,
    );
    canvas.drawLine(
      const Offset(18, 35),
      const Offset(52, 35),
      _stroke(_hourglassOpacity, 1.2, glyphAlpha: 0.5),
    );
    _drawRRect(
      canvas,
      28,
      32,
      14,
      6,
      2,
      _fill(_hourglassOpacity, glyphAlpha: 0.6),
    );
    canvas.restore();
  }

  // ─── Anchor ───────────────────────────────────────────────────────────
  void _paintAnchor(Canvas canvas) {
    canvas.save();
    canvas.translate(60, 860);
    final Paint stroke = _stroke(_anchorOpacity, 3.5);
    canvas.drawCircle(const Offset(58, 10), 11, stroke);
    final Paint solid = _fill(_anchorOpacity);
    _drawRRect(canvas, 53, 21, 10, 78, 4, solid);
    _drawRRect(canvas, 26, 32, 64, 6, 3, solid);
    final Paint hook = _stroke(_anchorOpacity, 6, cap: StrokeCap.round);
    final Path leftHook = Path()
      ..moveTo(53, 66)
      ..quadraticBezierTo(20, 72, 10, 90)
      ..quadraticBezierTo(22, 78, 53, 72);
    canvas.drawPath(leftHook, hook);
    final Path rightHook = Path()
      ..moveTo(63, 66)
      ..quadraticBezierTo(96, 72, 106, 90)
      ..quadraticBezierTo(94, 78, 63, 72);
    canvas.drawPath(rightHook, hook);
    final Paint fluke = _fill(_anchorOpacity, glyphAlpha: 0.9);
    canvas.drawPath(
      _polygon([
        const Offset(6, 86),
        const Offset(14, 86),
        const Offset(10, 102),
      ]),
      fluke,
    );
    canvas.drawPath(
      _polygon([
        const Offset(102, 86),
        const Offset(110, 86),
        const Offset(106, 102),
      ]),
      fluke,
    );
    canvas.restore();
  }

  // ─── Soldier silhouette ───────────────────────────────────────────────
  void _paintSoldier(Canvas canvas) {
    canvas.save();
    canvas.translate(1750, 230);
    final Paint solid = _fill(_soldierOpacity);
    canvas.drawPath(
      _polygon([
        const Offset(65, 10),
        const Offset(85, 48),
        const Offset(45, 48),
      ]),
      solid,
    );
    _drawRRect(canvas, 73, 5, 28, 12, 5, solid);
    canvas.drawCircle(const Offset(85, 56), 10, solid);
    _drawRRect(canvas, 70, 65, 30, 48, 6, solid);
    canvas.drawPath(
      _polygon([
        const Offset(70, 100),
        const Offset(54, 140),
        const Offset(80, 112),
      ]),
      solid,
    );
    canvas.drawPath(
      _polygon([
        const Offset(100, 100),
        const Offset(116, 140),
        const Offset(90, 112),
      ]),
      solid,
    );
    _drawRRect(canvas, 73, 110, 10, 44, 5, solid);
    _drawRRect(canvas, 87, 110, 10, 44, 5, solid);
    final Paint stock = _stroke(_soldierOpacity, 4, cap: StrokeCap.round);
    canvas.drawLine(const Offset(42, 52), const Offset(130, 130), stock);
    canvas.drawPath(
      _polygon([
        const Offset(42, 52),
        const Offset(34, 46),
        const Offset(38, 40),
      ]),
      solid,
    );
    canvas.drawPath(
      _polygon([
        const Offset(130, 130),
        const Offset(142, 136),
        const Offset(138, 144),
      ]),
      solid,
    );
    canvas.restore();
  }

  // ─── Ship's wheel ─────────────────────────────────────────────────────
  void _paintShipsWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(1660, 520);
    final Offset center = const Offset(65, 65);
    canvas.drawCircle(
      center,
      11,
      _fill(_shipsWheelOpacity, glyphAlpha: 0.9),
    );
    canvas.drawCircle(
      center,
      46,
      _stroke(_shipsWheelOpacity, 4.5, glyphAlpha: 0.7),
    );
    canvas.drawCircle(
      center,
      60,
      _stroke(_shipsWheelOpacity, 3, glyphAlpha: 0.5),
    );
    final Paint spoke = _stroke(_shipsWheelOpacity, 3.5);
    canvas.drawLine(const Offset(65, 8), const Offset(65, 56), spoke);
    canvas.drawLine(const Offset(65, 74), const Offset(65, 122), spoke);
    canvas.drawLine(const Offset(8, 65), const Offset(56, 65), spoke);
    canvas.drawLine(const Offset(74, 65), const Offset(122, 65), spoke);
    final Paint diagonalSpoke = _stroke(_shipsWheelOpacity, 2.2);
    canvas.drawLine(const Offset(25, 25), const Offset(52, 52), diagonalSpoke);
    canvas.drawLine(const Offset(78, 78), const Offset(105, 105), diagonalSpoke);
    canvas.drawLine(const Offset(25, 105), const Offset(52, 78), diagonalSpoke);
    canvas.drawLine(const Offset(78, 52), const Offset(105, 25), diagonalSpoke);
    final Paint handle = _fill(_shipsWheelOpacity, glyphAlpha: 0.9);
    canvas.drawCircle(const Offset(65, 6), 7, handle);
    canvas.drawCircle(const Offset(65, 124), 7, handle);
    canvas.drawCircle(const Offset(6, 65), 7, handle);
    canvas.drawCircle(const Offset(124, 65), 7, handle);
    canvas.restore();
  }

  // ─── Cannon ───────────────────────────────────────────────────────────
  void _paintCannon(Canvas canvas) {
    canvas.save();
    canvas.translate(1600, 800);
    final Paint wheelRim = _stroke(_cannonOpacity, 4);
    canvas.drawCircle(const Offset(38, 58), 22, wheelRim);
    canvas.drawCircle(const Offset(130, 58), 22, wheelRim);
    final Paint wheelHub = _fill(_cannonOpacity, glyphAlpha: 0.8);
    canvas.drawCircle(const Offset(38, 58), 7, wheelHub);
    canvas.drawCircle(const Offset(130, 58), 7, wheelHub);
    _drawRRect(
      canvas,
      20,
      18,
      128,
      24,
      5,
      _fill(_cannonOpacity, glyphAlpha: 0.8),
    );
    final Paint mount = _fill(_cannonOpacity, glyphAlpha: 0.7);
    _drawRRect(canvas, 30, 38, 7, 20, 3, mount);
    _drawRRect(canvas, 131, 38, 7, 20, 3, mount);
    canvas.drawPath(
      _polygon([
        const Offset(32, 24),
        const Offset(150, 10),
        const Offset(150, 20),
        const Offset(32, 36),
      ]),
      _fill(_cannonOpacity),
    );
    _drawRRect(canvas, 60, 12, 6, 15, 3, mount);
    _drawRRect(canvas, 105, 11, 6, 13, 3, mount);
    final Paint ball = _fill(_cannonOpacity, glyphAlpha: 0.6);
    canvas.drawCircle(const Offset(165, 28), 9, ball);
    canvas.drawCircle(const Offset(165, 48), 9, ball);
    canvas.drawCircle(const Offset(165, 68), 9, ball);
    canvas.drawCircle(const Offset(181, 38), 9, ball);
    canvas.restore();
  }

  // ─── Wave bands ───────────────────────────────────────────────────────
  void _paintWaves(Canvas canvas) {
    void band(double y, double amplitude, double strokeWidth) {
      final Path path = Path()..moveTo(0, y);
      const double dx = 40;
      // Smooth cycle: each control point alternates above/below to emit a
      // T-style continuation as the mockup's `Q ... T ... T ...` chain does.
      bool above = false;
      double prevY = y;
      for (double x = dx; x <= _viewBoxWidth; x += dx) {
        final double cx = x - dx / 2;
        final double cy = above ? y + amplitude : y - amplitude;
        path.quadraticBezierTo(cx, cy, x, prevY);
        above = !above;
      }
      canvas.drawPath(path, _stroke(_wavesOpacity, strokeWidth));
    }

    band(920, 30, 2);
    band(945, 27, 1.4);
    band(970, 22, 1);
    band(995, 17, 0.7);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  Path _polygon(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  double _deg(double degrees) => degrees * 3.1415926535897932 / 180;

  @override
  bool shouldRepaint(covariant _CtMainMenuCollagePainter oldDelegate) {
    return oldDelegate.glyphColor != glyphColor;
  }
}

/// Internal helper exposed for tests: returns the canonical SVG viewBox the
/// painter scales its glyphs from (`1920 x 1080`).
@visibleForTesting
Size get ctMainMenuCollageViewBoxForTesting => const Size(
  _CtMainMenuCollagePainter._viewBoxWidth,
  _CtMainMenuCollagePainter._viewBoxHeight,
);

/// Internal helper exposed for tests: returns the documented final group
/// alpha applied to every collage primitive (`.collage-svg { opacity }`).
@visibleForTesting
double get ctMainMenuCollageOpacityForTesting =>
    _CtMainMenuCollagePainter._collageOpacity;

/// Internal helper exposed for tests: returns the per-group opacity
/// multiplier for a given glyph family. Tests use this to pin the values
/// against the mockup `<g opacity>` attributes without parsing SVG.
@visibleForTesting
Map<String, double> ctMainMenuCollageGroupOpacitiesForTesting() => const {
  'tradeRoutes': _CtMainMenuCollagePainter._tradeRoutesOpacity,
  'waypoints': _CtMainMenuCollagePainter._waypointsOpacity,
  'telescope': _CtMainMenuCollagePainter._telescopeOpacity,
  'spyglass': _CtMainMenuCollagePainter._spyglassOpacity,
  'muskets': _CtMainMenuCollagePainter._musketsOpacity,
  'powderHorn': _CtMainMenuCollagePainter._powderHornOpacity,
  'sextant': _CtMainMenuCollagePainter._sextantOpacity,
  'hourglass': _CtMainMenuCollagePainter._hourglassOpacity,
  'anchor': _CtMainMenuCollagePainter._anchorOpacity,
  'soldier': _CtMainMenuCollagePainter._soldierOpacity,
  'shipsWheel': _CtMainMenuCollagePainter._shipsWheelOpacity,
  'cannon': _CtMainMenuCollagePainter._cannonOpacity,
  'waves': _CtMainMenuCollagePainter._wavesOpacity,
};
