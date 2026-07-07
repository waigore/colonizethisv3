part of 'ct_main_menu_collage.dart';

extension _CtMainMenuCollagePainterInstruments on _CtMainMenuCollagePainter {
  void _paintTelescope(Canvas canvas) {
    canvas.save();
    canvas.translate(140, 120);
    canvas.rotate(_deg(-14));
    final Paint full = _fill(_CtMainMenuCollagePainter._telescopeOpacity);
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
    final Paint band = _fill(_CtMainMenuCollagePainter._telescopeOpacity, glyphAlpha: 0.6);
    _drawRRect(canvas, 50, 16, 7, 18, 2.5, band);
    _drawRRect(canvas, 120, 19, 7, 15, 2.5, band);
    final Paint grip = _fill(_CtMainMenuCollagePainter._telescopeOpacity, glyphAlpha: 0.5);
    _drawRRect(canvas, 80, 27, 12, 32, 3, grip);
    canvas.restore();
  }

  void _paintSpyglass(Canvas canvas) {
    canvas.save();
    canvas.translate(190, 310);
    canvas.rotate(_deg(-6));
    final Paint full = _fill(_CtMainMenuCollagePainter._spyglassOpacity);
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
    final Paint band = _fill(_CtMainMenuCollagePainter._spyglassOpacity, glyphAlpha: 0.7);
    _drawRRect(canvas, 30, 8, 3.5, 9, 1.5, band);
    _drawRRect(canvas, 60, 10, 3.5, 7, 1.5, band);
    canvas.restore();
  }

  void _paintMuskets(Canvas canvas) {
    void musket(double tx, double ty, double rotationDeg) {
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(_deg(rotationDeg));
      final Paint barrel = _fill(_CtMainMenuCollagePainter._musketsOpacity);
      _drawRRect(canvas, 0, 9, 195, 6, 3, barrel);
      final Paint stockHigh = _fill(_CtMainMenuCollagePainter._musketsOpacity, glyphAlpha: 0.8);
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
      final Paint hammer = _fill(_CtMainMenuCollagePainter._musketsOpacity, glyphAlpha: 0.6);
      _drawRRect(canvas, 140, 11, 22, 8, 3, hammer);
      final Paint band = _fill(_CtMainMenuCollagePainter._musketsOpacity, glyphAlpha: 0.5);
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
    final Paint body = _fill(_CtMainMenuCollagePainter._powderHornOpacity);
    final Path horn = Path()
      ..moveTo(0, 15)
      ..quadraticBezierTo(20, 0, 60, 10)
      ..quadraticBezierTo(70, 20, 40, 30)
      ..quadraticBezierTo(10, 30, 0, 15)
      ..close();
    canvas.drawPath(horn, body);
    final Paint plug = _fill(_CtMainMenuCollagePainter._powderHornOpacity, glyphAlpha: 0.8);
    _drawRRect(canvas, -2, 10, 8, 4, 2, plug);
    canvas.restore();
  }

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
      _stroke(_CtMainMenuCollagePainter._sextantOpacity, 3.5, cap: StrokeCap.round),
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(70, 14),
      _stroke(_CtMainMenuCollagePainter._sextantOpacity, 2.2),
    );
    final Paint mount = _fill(_CtMainMenuCollagePainter._sextantOpacity, glyphAlpha: 0.6);
    canvas.save();
    canvas.translate(2, 0);
    canvas.rotate(_deg(-20));
    canvas.translate(-2, 0);
    _drawRRect(canvas, -4, -8, 12, 16, 2.5, mount);
    canvas.restore();
    _drawRRect(canvas, -6, 10, 9, 22, 3.5, mount);
    canvas.restore();
  }

  void _paintHourglass(Canvas canvas) {
    canvas.save();
    canvas.translate(130, 710);
    final Paint cap = _fill(_CtMainMenuCollagePainter._hourglassOpacity, glyphAlpha: 0.8);
    _drawRRect(canvas, 18, 0, 34, 6, 3, cap);
    _drawRRect(canvas, 18, 64, 34, 6, 3, cap);
    final Paint frame = _stroke(_CtMainMenuCollagePainter._hourglassOpacity, 2, glyphAlpha: 0.6);
    canvas.drawLine(const Offset(0, 3), const Offset(0, 67), frame);
    canvas.drawLine(const Offset(70, 3), const Offset(70, 67), frame);
    final Paint sand = _fill(_CtMainMenuCollagePainter._hourglassOpacity, glyphAlpha: 0.5);
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
      _stroke(_CtMainMenuCollagePainter._hourglassOpacity, 1.2, glyphAlpha: 0.5),
    );
    _drawRRect(
      canvas,
      28,
      32,
      14,
      6,
      2,
      _fill(_CtMainMenuCollagePainter._hourglassOpacity, glyphAlpha: 0.6),
    );
    canvas.restore();
  }
}
