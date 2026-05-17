import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'fleet_map_overlay.dart';

/// Visual scale factor applied to logical cellSize from RegionMapViewData.
/// Default 0.25 so both regions fit side-by-side in a typical viewport; zoom min 0.25.
const double kDebugMapScale = 0.25;

class RegionMapPainter extends CustomPainter {
  RegionMapPainter({
    required this.region,
    required this.cellSize,
    this.showOwnership = true,
    this.showCapitals = true,
    this.showPorts = true,
    this.geographicMode = false,
    this.showImprovements = false,
    this.showUnits = false,
    this.fleets = const [],
    this.selectedX,
    this.selectedY,
  });

  final RegionMapViewData region;
  final double cellSize;
  final bool showOwnership;
  final bool showCapitals;
  final bool showPorts;
  final bool geographicMode;
  final bool showImprovements;
  final bool showUnits;

  /// When [showUnits] is true, drawn as triangles (same toggle as armies).
  final List<Fleet> fleets;
  final int? selectedX;
  final int? selectedY;

  static const Color _seaColor = Color(0xFF003366);
  static const Color _landFallbackColor = Color(0xFF808080);
  static const Color _landBorderColor = Colors.black;
  static const Color _seaBorderColor = Color(0xFFADD8E6);

  @override
  void paint(Canvas canvas, Size size) {
    _drawTiles(canvas);
    _drawResourceGlyphs(canvas);
    _drawUnitMarkers(canvas);
    _drawFleets(canvas);
    _drawImprovements(canvas);
    _drawBorders(canvas);
    _drawPorts(canvas);
    _drawCapitals(canvas);
    _drawSelection(canvas);
  }

  void _drawTiles(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final cell in region.cells) {
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;
      paint.color = _tileColor(cell);
      canvas.drawRect(Rect.fromLTWH(left, top, cellSize, cellSize), paint);
    }
  }

  Color _tileColor(CellViewData cell) {
    if (cell.isSea) {
      return _seaColor;
    }
    if (geographicMode) {
      return _terrainColor(cell);
    }
    if (showOwnership) {
      final colorTuple =
          region.factionColors[cell.ownerFactionId] ?? (128, 128, 128);
      return Color.fromARGB(255, colorTuple.$1, colorTuple.$2, colorTuple.$3);
    }
    return _landFallbackColor;
  }

  Color _terrainColor(CellViewData cell) {
    final terrain =
        cell.terrainType ??
        (cell.terrainTypeId != null
            ? TerrainType.values.byName(cell.terrainTypeId!)
            : null);
    final terrainRgb = terrain != null
        ? (region.terrainColors[terrain] ?? (128, 128, 128))
        : (128, 128, 128);
    return Color.fromARGB(255, terrainRgb.$1, terrainRgb.$2, terrainRgb.$3);
  }

  void _drawResourceGlyphs(Canvas canvas) {
    if (!geographicMode) {
      return;
    }
    for (final cell in region.cells) {
      final letter = resourceIdToLegendLetter(cell.resourceId);
      if (letter == null) {
        continue;
      }
      final cx = cell.x * cellSize + cellSize / 2;
      final cy = cell.y * cellSize + cellSize / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: Colors.black,
            fontSize: math.max(8, cellSize * 0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  void _drawUnitMarkers(Canvas canvas) {
    if (!showUnits || region.unitMarkers.isEmpty) {
      return;
    }
    for (final marker in region.unitMarkers) {
      final cx = marker.x * cellSize + cellSize / 2;
      final cy = marker.y * cellSize + cellSize / 2;
      final colorTuple =
          region.factionColors[marker.ownerFactionId] ?? (128, 128, 128);
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.fromARGB(
          255,
          colorTuple.$1,
          colorTuple.$2,
          colorTuple.$3,
        );
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black;
      const radius = 5.0;
      canvas.drawCircle(Offset(cx, cy), radius, fillPaint);
      canvas.drawCircle(Offset(cx, cy), radius, strokePaint);
    }
  }

  void _drawFleets(Canvas canvas) {
    if (!showUnits || fleets.isEmpty) {
      return;
    }
    paintFleetsForRegion(canvas, region, fleets, cellSize);
  }

  void _drawImprovements(Canvas canvas) {
    if (!showImprovements) {
      return;
    }
    for (final cell in region.cells) {
      if (cell.isSea) {
        continue;
      }
      final imp = cell.improvementLevel ?? 0;
      final road = cell.roadLevel ?? 0;
      final cx = cell.x * cellSize + cellSize / 2;
      final cy = cell.y * cellSize + cellSize / 2;
      final fontSize = math.max(8, cellSize * 0.5);
      final text = 'i$imp r$road';
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize.toDouble(),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (cx - textPainter.width / 2).toDouble(),
          (cy - textPainter.height / 2).toDouble(),
        ),
      );
    }
  }

  void _drawBorders(Canvas canvas) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cellSize / 12);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        _drawRightEdgeBorder(canvas, borderPaint, cell, x, y);
        _drawBottomEdgeBorder(canvas, borderPaint, cell, x, y);
      }
    }
  }

  void _drawRightEdgeBorder(
    Canvas canvas,
    Paint borderPaint,
    CellViewData cell,
    int x,
    int y,
  ) {
    if (x + 1 >= region.width) {
      return;
    }
    final rightCell = region.cellAt(x + 1, y);
    if (cell.regionCellId == rightCell.regionCellId) {
      return;
    }
    final isSeaBorder = cell.isSea && rightCell.isSea;
    borderPaint.color = isSeaBorder ? _seaBorderColor : _landBorderColor;
    final xEdge = (x + 1) * cellSize;
    canvas.drawLine(
      Offset(xEdge, y * cellSize),
      Offset(xEdge, (y + 1) * cellSize),
      borderPaint,
    );
  }

  void _drawBottomEdgeBorder(
    Canvas canvas,
    Paint borderPaint,
    CellViewData cell,
    int x,
    int y,
  ) {
    if (y + 1 >= region.height) {
      return;
    }
    final bottomCell = region.cellAt(x, y + 1);
    if (cell.regionCellId == bottomCell.regionCellId) {
      return;
    }
    final isSeaBorder = cell.isSea && bottomCell.isSea;
    borderPaint.color = isSeaBorder ? _seaBorderColor : _landBorderColor;
    final yEdge = (y + 1) * cellSize;
    canvas.drawLine(
      Offset(x * cellSize, yEdge),
      Offset((x + 1) * cellSize, yEdge),
      borderPaint,
    );
  }

  void _drawPorts(Canvas canvas) {
    if (!showPorts || region.portMarkers.isEmpty) {
      return;
    }
    final portPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00648C);
    final portOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black;
    const halfSize = 4.0;
    for (final port in region.portMarkers) {
      final cx = port.x * cellSize + cellSize / 2;
      final cy = port.y * cellSize + cellSize / 2;
      final rect = Rect.fromLTWH(
        cx - halfSize,
        cy - halfSize,
        halfSize * 2,
        halfSize * 2,
      );
      canvas.drawRect(rect, portPaint);
      canvas.drawRect(rect, portOutline);
    }
  }

  void _drawCapitals(Canvas canvas) {
    if (!showCapitals || region.capitalMarkers.isEmpty) {
      return;
    }
    final capitalPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700);
    final capitalOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black;
    const radius = 6.0;
    for (final capital in region.capitalMarkers) {
      final cx = capital.x * cellSize + cellSize / 2;
      final cy = capital.y * cellSize + cellSize / 2;
      final center = Offset(cx, cy);
      canvas.drawCircle(center, radius, capitalPaint);
      canvas.drawCircle(center, radius, capitalOutline);
    }
  }

  void _drawSelection(Canvas canvas) {
    if (selectedX == null || selectedY == null) {
      return;
    }
    if (selectedX! < 0 || selectedX! >= region.width) {
      return;
    }
    if (selectedY! < 0 || selectedY! >= region.height) {
      return;
    }
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, cellSize / 10)
      ..color = Colors.white;
    final rect = Rect.fromLTWH(
      selectedX! * cellSize,
      selectedY! * cellSize,
      cellSize,
      cellSize,
    );
    canvas.drawRect(rect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant RegionMapPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.showOwnership != showOwnership ||
        oldDelegate.showCapitals != showCapitals ||
        oldDelegate.showPorts != showPorts ||
        oldDelegate.geographicMode != geographicMode ||
        oldDelegate.showImprovements != showImprovements ||
        oldDelegate.showUnits != showUnits ||
        oldDelegate.fleets != fleets ||
        oldDelegate.selectedX != selectedX ||
        oldDelegate.selectedY != selectedY;
  }
}

class CombinedMapPainter extends CustomPainter {
  CombinedMapPainter({
    required this.viewData,
    this.showOwnership = true,
    this.showCapitals = true,
    this.showPorts = true,
    this.geographicMode = false,
    this.showImprovements = false,
    this.showUnits = false,
    this.fleets = const [],
    this.selectedRegionId,
    this.selectedX,
    this.selectedY,
  });

  final InitGameMapViewData viewData;
  final bool showOwnership;
  final bool showCapitals;
  final bool showPorts;
  final bool geographicMode;
  final bool showImprovements;
  final bool showUnits;
  final List<Fleet> fleets;
  final String? selectedRegionId;
  final int? selectedX;
  final int? selectedY;

  @override
  void paint(Canvas canvas, Size size) {
    final ow = viewData.oldWorld;
    final nw = viewData.newWorld;
    final cellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = cellSize * 2;

    final owWidthPx = ow.width * cellSize;

    final owPainter = RegionMapPainter(
      region: ow,
      cellSize: cellSize,
      showOwnership: showOwnership,
      showCapitals: showCapitals,
      showPorts: showPorts,
      geographicMode: geographicMode,
      showImprovements: showImprovements,
      showUnits: showUnits,
      fleets: fleets,
      selectedX: selectedRegionId == ow.regionId ? selectedX : null,
      selectedY: selectedRegionId == ow.regionId ? selectedY : null,
    );
    owPainter.paint(canvas, Size(owWidthPx, ow.height * cellSize));

    canvas.save();
    canvas.translate(owWidthPx + gap, 0);
    final nwPainter = RegionMapPainter(
      region: nw,
      cellSize: cellSize,
      showOwnership: showOwnership,
      showCapitals: showCapitals,
      showPorts: showPorts,
      geographicMode: geographicMode,
      showImprovements: showImprovements,
      showUnits: showUnits,
      fleets: fleets,
      selectedX: selectedRegionId == nw.regionId ? selectedX : null,
      selectedY: selectedRegionId == nw.regionId ? selectedY : null,
    );
    nwPainter.paint(canvas, Size(nw.width * cellSize, nw.height * cellSize));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CombinedMapPainter oldDelegate) {
    return oldDelegate.viewData != viewData ||
        oldDelegate.showOwnership != showOwnership ||
        oldDelegate.showCapitals != showCapitals ||
        oldDelegate.showPorts != showPorts ||
        oldDelegate.geographicMode != geographicMode ||
        oldDelegate.showImprovements != showImprovements ||
        oldDelegate.showUnits != showUnits ||
        oldDelegate.fleets != fleets ||
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.selectedX != selectedX ||
        oldDelegate.selectedY != selectedY;
  }
}
