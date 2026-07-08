part of 'ct_main_menu_collage.dart';

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
