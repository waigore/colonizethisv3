import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_paint_colors.dart';

mixin VictoryPoliticalMinimapPaintOps on VictoryPoliticalMinimapPaintColors {
  void paintOwnershipCells(Canvas canvas, double cellW, double cellH) {
    final fillPaint = Paint();
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
        fillPaint.color = fillColorForCell(cell);
        canvas.drawRect(rect, fillPaint);
        drawHighlightIfSelected(canvas, rect, cell);
      }
    }
  }

  void paintProvinceBorders(
    Canvas canvas,
    double cellW,
    double cellH,
    Paint borderPaint,
    Set<String> capitalProvinceIds,
  ) {
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        drawCellProvinceBorders(
          canvas,
          x,
          y,
          cellW,
          cellH,
          borderPaint,
          capitalProvinceIds,
        );
      }
    }
  }

  void drawCellProvinceBorders(
    Canvas canvas,
    int x,
    int y,
    double cellW,
    double cellH,
    Paint borderPaint,
    Set<String> capitalProvinceIds,
  ) {
    final cell = region.cellAt(x, y);
    if (cell.isSea) return;

    final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);
    drawEastProvinceBorder(
      canvas,
      x,
      y,
      cell,
      rect,
      borderPaint,
      capitalProvinceIds,
    );
    drawSouthProvinceBorder(
      canvas,
      x,
      y,
      cell,
      rect,
      borderPaint,
      capitalProvinceIds,
    );
  }

  void drawEastProvinceBorder(
    Canvas canvas,
    int x,
    int y,
    CellViewData cell,
    Rect rect,
    Paint paint,
    Set<String> capitalProvinceIds,
  ) {
    if (x + 1 >= region.width) return;
    final east = region.cellAt(x + 1, y);
    if (east.regionCellId == cell.regionCellId) return;
    final eastIsCapital = capitalProvinceIds.contains(east.regionCellId);
    final stroke = borderPaintForEdge(
      cellIsCapital: capitalProvinceIds.contains(cell.regionCellId),
      neighborIsCapital: eastIsCapital,
      defaultPaint: paint,
    );
    canvas.drawLine(rect.topRight, rect.bottomRight, stroke);
  }

  void drawSouthProvinceBorder(
    Canvas canvas,
    int x,
    int y,
    CellViewData cell,
    Rect rect,
    Paint paint,
    Set<String> capitalProvinceIds,
  ) {
    if (y + 1 >= region.height) return;
    final south = region.cellAt(x, y + 1);
    if (south.regionCellId == cell.regionCellId) return;
    final southIsCapital = capitalProvinceIds.contains(south.regionCellId);
    final stroke = borderPaintForEdge(
      cellIsCapital: capitalProvinceIds.contains(cell.regionCellId),
      neighborIsCapital: southIsCapital,
      defaultPaint: paint,
    );
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, stroke);
  }

  void paintTownMarkers(Canvas canvas, double cellW, double cellH) {
    final fill = Paint()..color = EditorialMonoclePalette.fg;
    final stroke = Paint()
      ..color = EditorialMonoclePalette.bgDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final town in region.townMarkers) {
      final cx = (town.x + 0.5) * cellW;
      final cy = (town.y + 0.5) * cellH;
      final radius = mathMinCell(cellW, cellH) * 0.18;
      canvas.drawCircle(Offset(cx, cy), radius, fill);
      canvas.drawCircle(Offset(cx, cy), radius, stroke);
    }
  }

  double mathMinCell(double cellW, double cellH) =>
      cellW < cellH ? cellW : cellH;
}
