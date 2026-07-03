// Compact nation-color pennant for GP tech indicators. SPEC/ui/components/gp-nation-color-pennant.md.

import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Pennant / banner shape filled with a GP map-ownership color.
///
/// [highlighted] uses [EditorialMonoclePalette.accent] border; standard chrome
/// uses [EditorialMonoclePalette.border].
class GpNationColorPennant extends StatelessWidget {
  const GpNationColorPennant({
    super.key,
    required this.color,
    this.highlighted = false,
    this.size = const Size(10, 12),
  });

  final Color color;
  final bool highlighted;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _GpNationColorPennantPainter(
          fillColor: color,
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _GpNationColorPennantPainter extends CustomPainter {
  const _GpNationColorPennantPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final staffWidth = size.width * 0.22;
    final flyLeft = staffWidth;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(flyLeft, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(flyLeft, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GpNationColorPennantPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
