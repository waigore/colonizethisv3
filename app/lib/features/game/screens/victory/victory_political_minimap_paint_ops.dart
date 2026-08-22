import 'dart:math' as math;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_annotations.dart';

const double kVictoryMinimapSmallProvinceCellThreshold = 4;
const double kVictoryMinimapLabelFontSize = 9;
const double kVictoryMinimapSmallLabelFontSize = 7;

mixin VictoryPoliticalMinimapPaintOps on CustomPainter {
  RegionMapViewData get region;
  String? get highlightedProvinceLocalId;
  String? get selectedFactionId;

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

  Color fillColorForCell(CellViewData cell) {
    if (cell.isSea) {
      return EditorialMonoclePalette.bgDeep;
    }
    final rgb =
        region.factionColors[cell.ownerFactionId ?? ''] ?? (128, 128, 128);
    final base = Color.fromRGBO(rgb.$1, rgb.$2, rgb.$3, 1.0);
    final selected = selectedFactionId;
    if (selected == null) return base;
    final owner = cell.ownerFactionId;
    if (owner == selected) {
      return base;
    }
    return base.withValues(alpha: 0.28);
  }

  void drawHighlightIfSelected(Canvas canvas, Rect rect, CellViewData cell) {
    if (cell.isSea) return;
    final selectedId = highlightedProvinceLocalId;
    if (selectedId == null || cell.regionCellId != selectedId) return;

    final highlight = Paint()
      ..color = EditorialMonoclePalette.accentBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect.deflate(0.5), highlight);
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

  Paint borderPaintForEdge({
    required bool cellIsCapital,
    required bool neighborIsCapital,
    required Paint defaultPaint,
  }) {
    if (cellIsCapital || neighborIsCapital) {
      return Paint()
        ..color = EditorialMonoclePalette.accentBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75;
    }
    return defaultPaint;
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
      final radius = math.min(cellW, cellH) * 0.18;
      canvas.drawCircle(Offset(cx, cy), radius, fill);
      canvas.drawCircle(Offset(cx, cy), radius, stroke);
    }
  }

  void paintProvinceLabels(Canvas canvas, double cellW, double cellH) {
    final labels = computeVictoryMinimapProvinceLabels(region);
    for (final label in labels) {
      final isSmall =
          label.cellCount < kVictoryMinimapSmallProvinceCellThreshold;
      final fontSize = isSmall
          ? kVictoryMinimapSmallLabelFontSize
          : kVictoryMinimapLabelFontSize;
      final maxWidth = label.cellCount * math.min(cellW, cellH) * 0.95;
      final text = isSmall
          ? ellipsizeLabel(label.text, maxWidth, fontSize)
          : label.text;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: EditorialMonoclePalette.fg,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                blurRadius: 2,
                color: Color(0xCC000000),
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      final offset = Offset(
        label.cx * cellW - painter.width / 2,
        label.cy * cellH - painter.height / 2,
      );
      painter.paint(canvas, offset);
    }
  }

  String ellipsizeLabel(String text, double maxWidth, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    return painter.text?.toPlainText() ?? text;
  }
}
