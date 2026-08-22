import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'victory_political_minimap_annotations.dart';
import 'victory_political_minimap_paint_ops.dart';

/// Paints Old World political ownership for the Victory panel minimap.
class VictoryPoliticalMinimapPainter extends CustomPainter
    with VictoryPoliticalMinimapPaintOps {
  VictoryPoliticalMinimapPainter({
    required this.region,
    this.highlightedProvinceLocalId,
    this.selectedFactionId,
  });

  @override
  final RegionMapViewData region;
  @override
  final String? highlightedProvinceLocalId;
  @override
  final String? selectedFactionId;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / region.width;
    final cellH = size.height / region.height;
    final capitalProvinceIds = computeVictoryMinimapCapitalProvinceLocalIds(
      region,
    );
    final borderPaint = Paint()
      ..color = EditorialMonoclePalette.border.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    paintOwnershipCells(canvas, cellW, cellH);
    paintProvinceBorders(canvas, cellW, cellH, borderPaint, capitalProvinceIds);
    paintTownMarkers(canvas, cellW, cellH);
    paintProvinceLabels(canvas, cellW, cellH);
  }

  @override
  bool shouldRepaint(covariant VictoryPoliticalMinimapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.highlightedProvinceLocalId != highlightedProvinceLocalId ||
        oldDelegate.selectedFactionId != selectedFactionId;
  }
}
