import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';

/// Four 10x10 L-shaped brass corner overlays positioned at each corner of
/// the parent button surface. Painted via [CustomPaint] so the brackets
/// stay crisp at any DPR (no rasterised asset).
class CtNinePatchButtonBrackets extends StatelessWidget {
  const CtNinePatchButtonBrackets({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CtNinePatchButtonBracketsPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class CtNinePatchButtonBracketsPainter extends CustomPainter {
  CtNinePatchButtonBracketsPainter({required this.color});

  final Color color;

  static const double _bracketLength = CtNinePatchButton.cornerBracketSize;
  static const double _bracketThickness =
      CtNinePatchButton.cornerBracketThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double w = size.width;
    final double h = size.height;
    _paintCorner(canvas, paint, Offset.zero, 1, 1);
    _paintCorner(canvas, paint, Offset(w, 0), -1, 1);
    _paintCorner(canvas, paint, Offset(0, h), 1, -1);
    _paintCorner(canvas, paint, Offset(w, h), -1, -1);
  }

  void _paintCorner(
    Canvas canvas,
    Paint paint,
    Offset anchor,
    double dx,
    double dy,
  ) {
    final Rect horizontal = Rect.fromLTWH(
      dx > 0 ? anchor.dx : anchor.dx - _bracketLength,
      dy > 0 ? anchor.dy : anchor.dy - _bracketThickness,
      _bracketLength,
      _bracketThickness,
    );
    final Rect vertical = Rect.fromLTWH(
      dx > 0 ? anchor.dx : anchor.dx - _bracketThickness,
      dy > 0 ? anchor.dy : anchor.dy - _bracketLength,
      _bracketThickness,
      _bracketLength,
    );
    canvas.drawRect(horizontal, paint);
    canvas.drawRect(vertical, paint);
  }

  @override
  bool shouldRepaint(covariant CtNinePatchButtonBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
