import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'victory_overlay_panel_layout.dart';

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
      width: VictoryPanelLayout.cornerBracketWidth,
      height: VictoryPanelLayout.cornerBracketHeight,
      child: CustomPaint(
        painter: _VictoryCornerBracketPainter(
          color: EditorialMonoclePalette.accent.withValues(
            alpha: VictoryPanelLayout.cornerBracketAlpha,
          ),
          stroke: VictoryPanelLayout.cornerBracketStroke,
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

/// Top-left corner bracket for [VictoryPanel].
Widget victoryPanelTopLeftCornerBracket() {
  return const _VictoryCornerBracket(corner: _CornerSide.topLeft);
}

/// Bottom-right corner bracket for [VictoryPanel].
Widget victoryPanelBottomRightCornerBracket() {
  return const _VictoryCornerBracket(corner: _CornerSide.bottomRight);
}
