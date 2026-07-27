import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

/// Paints Old World political ownership for the Victory panel minimap.
class VictoryPoliticalMinimapPainter extends CustomPainter {
  VictoryPoliticalMinimapPainter({
    required this.region,
    this.highlightedProvinceLocalId,
  });

  final RegionMapViewData region;
  final String? highlightedProvinceLocalId;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / region.width;
    final cellH = size.height / region.height;
    final fillPaint = Paint();
    final borderPaint = Paint()
      ..color = EditorialMonoclePalette.border.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        if (cell.isSea) {
          fillPaint.color = EditorialMonoclePalette.bgDeep;
        } else {
          final rgb = region.factionColors[cell.ownerFactionId ?? ''] ??
              (128, 128, 128);
          fillPaint.color = Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1.0);
        }
        canvas.drawRect(rect, fillPaint);
        if (!cell.isSea &&
            highlightedProvinceLocalId != null &&
            cell.regionCellId == highlightedProvinceLocalId) {
          final highlight = Paint()
            ..color = EditorialMonoclePalette.accentBright
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRect(rect.deflate(0.5), highlight);
        }
      }
    }

    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (cell.isSea) continue;
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        if (x + 1 < region.width) {
          final east = region.cellAt(x + 1, y);
          if (east.regionCellId != cell.regionCellId) {
            canvas.drawLine(rect.topRight, rect.bottomRight, borderPaint);
          }
        }
        if (y + 1 < region.height) {
          final south = region.cellAt(x, y + 1);
          if (south.regionCellId != cell.regionCellId) {
            canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant VictoryPoliticalMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.highlightedProvinceLocalId != highlightedProvinceLocalId;
  }
}
