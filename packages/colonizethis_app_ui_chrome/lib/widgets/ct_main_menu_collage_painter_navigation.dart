part of 'ct_main_menu_collage.dart';

extension _CtMainMenuCollagePainterNavigation on _CtMainMenuCollagePainter {
  void _paintTradeRoutes(Canvas canvas) {
    final Paint thick = _stroke(_CtMainMenuCollagePainter._tradeRoutesOpacity, 1.2);
    final Paint thin = _stroke(_CtMainMenuCollagePainter._tradeRoutesOpacity, 1.0);

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

  void _paintWaypoints(Canvas canvas) {
    final Paint fill = _fill(_CtMainMenuCollagePainter._waypointsOpacity);
    final Paint stroke = _stroke(_CtMainMenuCollagePainter._waypointsOpacity, 0.8);

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
}
