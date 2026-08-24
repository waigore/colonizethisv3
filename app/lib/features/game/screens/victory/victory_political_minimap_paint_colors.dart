import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

mixin VictoryPoliticalMinimapPaintColors on CustomPainter {
  RegionMapViewData get region;
  String? get highlightedProvinceLocalId;
  String? get selectedFactionId;

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
}
