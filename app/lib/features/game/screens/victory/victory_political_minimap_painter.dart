import 'dart:math' as math;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_annotations.dart';

/// Paints Old World political ownership for the Victory panel minimap.
class VictoryPoliticalMinimapPainter extends CustomPainter {
  VictoryPoliticalMinimapPainter({
    required this.region,
    this.highlightedProvinceLocalId,
  });

  final RegionMapViewData region;
  final String? highlightedProvinceLocalId;

  static const double _kSmallProvinceCellThreshold = 4;
  static const double _kLabelFontSize = 9;
  static const double _kSmallLabelFontSize = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / region.width;
    final cellH = size.height / region.height;
    final capitalProvinceIds =
        computeVictoryMinimapCapitalProvinceLocalIds(region);
    final borderPaint = Paint()
      ..color = EditorialMonoclePalette.border.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    _paintOwnershipCells(canvas, cellW, cellH);
    _paintProvinceBorders(
      canvas,
      cellW,
      cellH,
      borderPaint,
      capitalProvinceIds,
    );
    _paintTownMarkers(canvas, cellW, cellH);
    _paintProvinceLabels(canvas, cellW, cellH);
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
    Set<String> capitalProvinceIds,
  ) {
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        _drawCellProvinceBorders(
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

  void _drawCellProvinceBorders(
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
    _drawEastProvinceBorder(
      canvas,
      x,
      y,
      cell,
      rect,
      borderPaint,
      capitalProvinceIds,
    );
    _drawSouthProvinceBorder(
      canvas,
      x,
      y,
      cell,
      rect,
      borderPaint,
      capitalProvinceIds,
    );
  }

  void _drawEastProvinceBorder(
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
    final stroke = _borderPaintForEdge(
      cellIsCapital: capitalProvinceIds.contains(cell.regionCellId),
      neighborIsCapital: eastIsCapital,
      defaultPaint: paint,
    );
    canvas.drawLine(rect.topRight, rect.bottomRight, stroke);
  }

  void _drawSouthProvinceBorder(
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
    final stroke = _borderPaintForEdge(
      cellIsCapital: capitalProvinceIds.contains(cell.regionCellId),
      neighborIsCapital: southIsCapital,
      defaultPaint: paint,
    );
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, stroke);
  }

  Paint _borderPaintForEdge({
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

  void _paintTownMarkers(Canvas canvas, double cellW, double cellH) {
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

  void _paintProvinceLabels(Canvas canvas, double cellW, double cellH) {
    final labels = computeVictoryMinimapProvinceLabels(region);
    for (final label in labels) {
      final isSmall = label.cellCount < _kSmallProvinceCellThreshold;
      final fontSize = isSmall ? _kSmallLabelFontSize : _kLabelFontSize;
      final maxWidth = label.cellCount * math.min(cellW, cellH) * 0.95;
      final text = isSmall ? _ellipsize(label.text, maxWidth, fontSize) : label.text;
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

  String _ellipsize(String text, double maxWidth, double fontSize) {
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

  @override
  bool shouldRepaint(covariant VictoryPoliticalMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.highlightedProvinceLocalId != highlightedProvinceLocalId;
  }
}
