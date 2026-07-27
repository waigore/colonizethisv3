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
    final borderPaint = Paint()
      ..color = EditorialMonoclePalette.border.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    _paintOwnershipCells(canvas, cellW, cellH);
    _paintProvinceBorders(canvas, cellW, cellH, borderPaint);
  }

  void _paintOwnershipCells(Canvas canvas, double cellW, double cellH) {
    final fillPaint = Paint();
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        fillPaint.color = _fillColorForCell(cell);
        canvas.drawRect(rect, fillPaint);
        _drawHighlightIfSelected(canvas, rect, cell);
      }
    }
  }

  Color _fillColorForCell(CellViewData cell) {
    if (cell.isSea) {
      return EditorialMonoclePalette.bgDeep;
    }
    final rgb =
        region.factionColors[cell.ownerFactionId ?? ''] ?? (128, 128, 128);
    return Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1.0);
  }

  void _drawHighlightIfSelected(
    Canvas canvas,
    Rect rect,
    CellViewData cell,
  ) {
    if (cell.isSea) return;
    final selectedId = highlightedProvinceLocalId;
    if (selectedId == null || cell.regionCellId != selectedId) return;

    final highlight = Paint()
      ..color = EditorialMonoclePalette.accentBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect.deflate(0.5), highlight);
  }

  void _paintProvinceBorders(
    Canvas canvas,
    double cellW,
    double cellH,
    Paint borderPaint,
  ) {
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        _drawCellProvinceBorders(canvas, x, y, cellW, cellH, borderPaint);
      }
    }
  }

  void _drawCellProvinceBorders(
    Canvas canvas,
    int x,
    int y,
    double cellW,
    double cellH,
    Paint borderPaint,
  ) {
    final cell = region.cellAt(x, y);
    if (cell.isSea) return;

    final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
    _drawEastProvinceBorder(canvas, x, y, cell, rect, borderPaint);
    _drawSouthProvinceBorder(canvas, x, y, cell, rect, borderPaint);
  }

  void _drawEastProvinceBorder(
    Canvas canvas,
    int x,
    int y,
    CellViewData cell,
    Rect rect,
    Paint borderPaint,
  ) {
    if (x + 1 >= region.width) return;
    final east = region.cellAt(x + 1, y);
    if (east.regionCellId == cell.regionCellId) return;
    canvas.drawLine(rect.topRight, rect.bottomRight, borderPaint);
  }

  void _drawSouthProvinceBorder(
    Canvas canvas,
    int x,
    int y,
    CellViewData cell,
    Rect rect,
    Paint borderPaint,
  ) {
    if (y + 1 >= region.height) return;
    final south = region.cellAt(x, y + 1);
    if (south.regionCellId == cell.regionCellId) return;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderPaint);
  }

  @override
  bool shouldRepaint(covariant VictoryPoliticalMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.highlightedProvinceLocalId != highlightedProvinceLocalId;
  }
}
