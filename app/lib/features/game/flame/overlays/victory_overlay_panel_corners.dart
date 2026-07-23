part of 'victory_overlay.dart';

enum _CornerSide { topLeft, bottomRight }

/// Asymmetric corner-bracket ornament drawn for the top-left and
/// bottom-right corners of the victory panel surface. Renders a 1.5px brass
/// L-shape at `cornerBracketAlpha` opacity.
class _VictoryCornerBracket extends StatelessWidget {
  const _VictoryCornerBracket({required this.corner});

  final _CornerSide corner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: VictoryPanel.cornerBracketWidth,
      height: VictoryPanel.cornerBracketHeight,
      child: CustomPaint(
        painter: _VictoryCornerBracketPainter(
          color: EditorialMonoclePalette.accent.withValues(
            alpha: VictoryPanel.cornerBracketAlpha,
          ),
          stroke: VictoryPanel.cornerBracketStroke,
          corner: corner,
        ),
      ),
    );
  }
}

class _VictoryCornerBracketPainter extends CustomPainter {
  _VictoryCornerBracketPainter({
    required this.color,
    required this.stroke,
    required this.corner,
  });

  final Color color;
  final double stroke;
  final _CornerSide corner;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    final double half = stroke / 2;
    switch (corner) {
      case _CornerSide.topLeft:
        canvas.drawLine(
          Offset(0, half),
          Offset(size.width, half),
          paint,
        );
        canvas.drawLine(
          Offset(half, 0),
          Offset(half, size.height),
          paint,
        );
        break;
      case _CornerSide.bottomRight:
        canvas.drawLine(
          Offset(0, size.height - half),
          Offset(size.width, size.height - half),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - half, 0),
          Offset(size.width - half, size.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_VictoryCornerBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stroke != stroke ||
        oldDelegate.corner != corner;
  }
}
