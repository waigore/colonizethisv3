part of 'ct_brass_divider.dart';

class _CtBrassDividerPainter extends CustomPainter {
  _CtBrassDividerPainter({
    required this.lineColor,
    required this.diamondFill,
    required this.diamondOutline,
    required this.dotColor,
  });

  final Color lineColor;
  final Color diamondFill;
  final Color diamondOutline;
  final Color dotColor;

  static const double _diamondSize = 8;
  static const double _diamondHalfDiagonal = _diamondSize / 2;
  static const double _dotRadius = 2;
  static const double _firstDotOffsetFromDiamond = 6;
  static const double _dotSpacing = 4;
  static const int _dotsPerSide = 3;
  static const double _lineThickness = 1;
  static const double _outlineWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double centerX = size.width / 2;

    _paintGradientLine(canvas, size, centerY);
    _paintDots(canvas, centerX, centerY);
    _paintDiamond(canvas, centerX, centerY);
  }

  void _paintGradientLine(Canvas canvas, Size size, double centerY) {
    final Rect lineRect = Rect.fromLTWH(
      0,
      centerY - _lineThickness / 2,
      size.width,
      _lineThickness,
    );
    final Paint linePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          lineColor.withValues(alpha: 0),
          lineColor,
          lineColor.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(lineRect);
    canvas.drawRect(lineRect, linePaint);
  }

  void _paintDots(Canvas canvas, double centerX, double centerY) {
    final Paint dotPaint = Paint()..color = dotColor;
    for (int i = 0; i < _dotsPerSide; i++) {
      final double offset =
          _diamondHalfDiagonal + _firstDotOffsetFromDiamond + _dotSpacing * i;
      canvas.drawCircle(
        Offset(centerX - offset, centerY),
        _dotRadius,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(centerX + offset, centerY),
        _dotRadius,
        dotPaint,
      );
    }
  }

  void _paintDiamond(Canvas canvas, double centerX, double centerY) {
    final Path diamond = Path()
      ..moveTo(centerX, centerY - _diamondHalfDiagonal)
      ..lineTo(centerX + _diamondHalfDiagonal, centerY)
      ..lineTo(centerX, centerY + _diamondHalfDiagonal)
      ..lineTo(centerX - _diamondHalfDiagonal, centerY)
      ..close();

    final Paint fillPaint = Paint()
      ..color = diamondFill
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamond, fillPaint);

    final Paint outlinePaint = Paint()
      ..color = diamondOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineWidth;
    canvas.drawPath(diamond, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _CtBrassDividerPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.diamondFill != diamondFill ||
        oldDelegate.diamondOutline != diamondOutline ||
        oldDelegate.dotColor != dotColor;
  }
}
