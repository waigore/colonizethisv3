part of 'ct_main_menu_collage.dart';

extension _CtMainMenuCollagePainterMaritime on _CtMainMenuCollagePainter {
  void _paintAnchor(Canvas canvas) {
    canvas.save();
    canvas.translate(60, 860);
    final Paint stroke = _stroke(_CtMainMenuCollagePainter._anchorOpacity, 3.5);
    canvas.drawCircle(const Offset(58, 10), 11, stroke);
    final Paint solid = _fill(_CtMainMenuCollagePainter._anchorOpacity);
    _drawRRect(canvas, 53, 21, 10, 78, 4, solid);
    _drawRRect(canvas, 26, 32, 64, 6, 3, solid);
    final Paint hook = _stroke(_CtMainMenuCollagePainter._anchorOpacity, 6, cap: StrokeCap.round);
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
    final Paint fluke = _fill(_CtMainMenuCollagePainter._anchorOpacity, glyphAlpha: 0.9);
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

  void _paintSoldier(Canvas canvas) {
    canvas.save();
    canvas.translate(1750, 230);
    final Paint solid = _fill(_CtMainMenuCollagePainter._soldierOpacity);
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
    final Paint stock = _stroke(_CtMainMenuCollagePainter._soldierOpacity, 4, cap: StrokeCap.round);
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

  void _paintShipsWheel(Canvas canvas) {
    canvas.save();
    canvas.translate(1660, 520);
    final Offset center = const Offset(65, 65);
    canvas.drawCircle(
      center,
      11,
      _fill(_CtMainMenuCollagePainter._shipsWheelOpacity, glyphAlpha: 0.9),
    );
    canvas.drawCircle(
      center,
      46,
      _stroke(_CtMainMenuCollagePainter._shipsWheelOpacity, 4.5, glyphAlpha: 0.7),
    );
    canvas.drawCircle(
      center,
      60,
      _stroke(_CtMainMenuCollagePainter._shipsWheelOpacity, 3, glyphAlpha: 0.5),
    );
    final Paint spoke = _stroke(_CtMainMenuCollagePainter._shipsWheelOpacity, 3.5);
    canvas.drawLine(const Offset(65, 8), const Offset(65, 56), spoke);
    canvas.drawLine(const Offset(65, 74), const Offset(65, 122), spoke);
    canvas.drawLine(const Offset(8, 65), const Offset(56, 65), spoke);
    canvas.drawLine(const Offset(74, 65), const Offset(122, 65), spoke);
    final Paint diagonalSpoke = _stroke(_CtMainMenuCollagePainter._shipsWheelOpacity, 2.2);
    canvas.drawLine(const Offset(25, 25), const Offset(52, 52), diagonalSpoke);
    canvas.drawLine(const Offset(78, 78), const Offset(105, 105), diagonalSpoke);
    canvas.drawLine(const Offset(25, 105), const Offset(52, 78), diagonalSpoke);
    canvas.drawLine(const Offset(78, 52), const Offset(105, 25), diagonalSpoke);
    final Paint handle = _fill(_CtMainMenuCollagePainter._shipsWheelOpacity, glyphAlpha: 0.9);
    canvas.drawCircle(const Offset(65, 6), 7, handle);
    canvas.drawCircle(const Offset(65, 124), 7, handle);
    canvas.drawCircle(const Offset(6, 65), 7, handle);
    canvas.drawCircle(const Offset(124, 65), 7, handle);
    canvas.restore();
  }

  void _paintCannon(Canvas canvas) {
    canvas.save();
    canvas.translate(1600, 800);
    final Paint wheelRim = _stroke(_CtMainMenuCollagePainter._cannonOpacity, 4);
    canvas.drawCircle(const Offset(38, 58), 22, wheelRim);
    canvas.drawCircle(const Offset(130, 58), 22, wheelRim);
    final Paint wheelHub = _fill(_CtMainMenuCollagePainter._cannonOpacity, glyphAlpha: 0.8);
    canvas.drawCircle(const Offset(38, 58), 7, wheelHub);
    canvas.drawCircle(const Offset(130, 58), 7, wheelHub);
    _drawRRect(
      canvas,
      20,
      18,
      128,
      24,
      5,
      _fill(_CtMainMenuCollagePainter._cannonOpacity, glyphAlpha: 0.8),
    );
    final Paint mount = _fill(_CtMainMenuCollagePainter._cannonOpacity, glyphAlpha: 0.7);
    _drawRRect(canvas, 30, 38, 7, 20, 3, mount);
    _drawRRect(canvas, 131, 38, 7, 20, 3, mount);
    canvas.drawPath(
      _polygon([
        const Offset(32, 24),
        const Offset(150, 10),
        const Offset(150, 20),
        const Offset(32, 36),
      ]),
      _fill(_CtMainMenuCollagePainter._cannonOpacity),
    );
    _drawRRect(canvas, 60, 12, 6, 15, 3, mount);
    _drawRRect(canvas, 105, 11, 6, 13, 3, mount);
    final Paint ball = _fill(_CtMainMenuCollagePainter._cannonOpacity, glyphAlpha: 0.6);
    canvas.drawCircle(const Offset(165, 28), 9, ball);
    canvas.drawCircle(const Offset(165, 48), 9, ball);
    canvas.drawCircle(const Offset(165, 68), 9, ball);
    canvas.drawCircle(const Offset(181, 38), 9, ball);
    canvas.restore();
  }

  void _paintWaves(Canvas canvas) {
    void band(double y, double amplitude, double strokeWidth) {
      final Path path = Path()..moveTo(0, y);
      const double dx = 40;
      // Smooth cycle: each control point alternates above/below to emit a
      // T-style continuation as the mockup's `Q ... T ... T ...` chain does.
      bool above = false;
      double prevY = y;
      for (double x = dx; x <= _CtMainMenuCollagePainter._viewBoxWidth; x += dx) {
        final double cx = x - dx / 2;
        final double cy = above ? y + amplitude : y - amplitude;
        path.quadraticBezierTo(cx, cy, x, prevY);
        above = !above;
      }
      canvas.drawPath(path, _stroke(_CtMainMenuCollagePainter._wavesOpacity, strokeWidth));
    }

    band(920, 30, 2);
    band(945, 27, 1.4);
    band(970, 22, 1);
    band(995, 17, 0.7);
  }
}
