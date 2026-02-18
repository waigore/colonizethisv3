import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

/// Visual scale factor applied to logical cellSize from RegionMapViewData.
/// Keeps tiles readable while fitting more of the map in a typical viewport.
/// In ctdev, we default this to 1.0 so tiles are easy to inspect without zooming.
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
  final int? selectedX;
  final int? selectedY;

  static const Color _seaColor = Color(0xFF003366);
  static const Color _landFallbackColor = Color(0xFF808080);
  static const Color _landBorderColor = Colors.black;
  static const Color _seaBorderColor = Color(0xFFADD8E6);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill tiles.
    final paint = Paint()..style = PaintingStyle.fill;
    for (final cell in region.cells) {
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;
      if (cell.isSea) {
        paint.color = _seaColor;
      } else if (geographicMode) {
        // Geographic view: fill by terrain type (enum lookup).
        final terrain = cell.terrainType ??
            (cell.terrainTypeId != null
                ? TerrainType.values.byName(cell.terrainTypeId!)
                : null);
        final terrainRgb = terrain != null
            ? (region.terrainColors[terrain] ?? (128, 128, 128))
            : (128, 128, 128);
        paint.color = Color.fromARGB(
          255,
          terrainRgb.$1,
          terrainRgb.$2,
          terrainRgb.$3,
        );
      } else if (!geographicMode && showOwnership) {
        final colorTuple =
            region.factionColors[cell.ownerFactionId] ?? (128, 128, 128);
        paint.color = Color.fromARGB(
          255,
          colorTuple.$1,
          colorTuple.$2,
          colorTuple.$3,
        );
      } else {
        paint.color = _landFallbackColor;
      }
      canvas.drawRect(
        Rect.fromLTWH(left, top, cellSize, cellSize),
        paint,
      );
    }

    // Resource glyphs (geographic view): g/t/i at cell centre.
    if (geographicMode) {
      for (final cell in region.cells) {
        final letter = resourceIdToLegendLetter(cell.resourceId);
        if (letter == null) continue;
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
          Offset(
            cx - textPainter.width / 2,
            cy - textPainter.height / 2,
          ),
        );
      }
    }

    // Units overlay: army markers per province, colored by owner.
    if (showUnits && region.unitMarkers.isNotEmpty) {
      for (final m in region.unitMarkers) {
        final cx = m.x * cellSize + cellSize / 2;
        final cy = m.y * cellSize + cellSize / 2;
        final colorTuple =
            region.factionColors[m.ownerFactionId] ?? (128, 128, 128);
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

    // Improvements overlay: improvement level (0-4) and road level on land tiles.
    if (showImprovements) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
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

    // Borders between differing regionCellId neighbours.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cellSize / 12);
    for (var y = 0; y < region.height; y++) {
      for (var x = 0; x < region.width; x++) {
        final cell = region.cellAt(x, y);
        if (x + 1 < region.width) {
          final rightCell = region.cellAt(x + 1, y);
          if (cell.regionCellId != rightCell.regionCellId) {
            final isSeaBorder = cell.isSea && rightCell.isSea;
            borderPaint.color =
                isSeaBorder ? _seaBorderColor : _landBorderColor;
            final xEdge = (x + 1) * cellSize;
            canvas.drawLine(
              Offset(xEdge, y * cellSize),
              Offset(xEdge, (y + 1) * cellSize),
              borderPaint,
            );
          }
        }
        if (y + 1 < region.height) {
          final bottomCell = region.cellAt(x, y + 1);
          if (cell.regionCellId != bottomCell.regionCellId) {
            final isSeaBorder = cell.isSea && bottomCell.isSea;
            borderPaint.color =
                isSeaBorder ? _seaBorderColor : _landBorderColor;
            final yEdge = (y + 1) * cellSize;
            canvas.drawLine(
              Offset(x * cellSize, yEdge),
              Offset((x + 1) * cellSize, yEdge),
              borderPaint,
            );
          }
        }
      }
    }

    // Ports.
    if (showPorts && region.portMarkers.isNotEmpty) {
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

    // Capitals.
    if (showCapitals && region.capitalMarkers.isNotEmpty) {
      final capitalPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFD700);
      final capitalOutline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black;
      final radius = 6.0;
      for (final cap in region.capitalMarkers) {
        final cx = cap.x * cellSize + cellSize / 2;
        final cy = cap.y * cellSize + cellSize / 2;
        final center = Offset(cx, cy);
        canvas.drawCircle(center, radius, capitalPaint);
        canvas.drawCircle(center, radius, capitalOutline);
      }
    }

    // Highlight selected tile, if any.
    if (selectedX != null &&
        selectedY != null &&
        selectedX! >= 0 &&
        selectedX! < region.width &&
        selectedY! >= 0 &&
        selectedY! < region.height) {
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
      selectedX:
          selectedRegionId == ow.regionId ? selectedX : null,
      selectedY:
          selectedRegionId == ow.regionId ? selectedY : null,
    );
    owPainter.paint(
      canvas,
      Size(owWidthPx, ow.height * cellSize),
    );

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
      selectedX:
          selectedRegionId == nw.regionId ? selectedX : null,
      selectedY:
          selectedRegionId == nw.regionId ? selectedY : null,
    );
    nwPainter.paint(
      canvas,
      Size(nw.width * cellSize, nw.height * cellSize),
    );
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
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.selectedX != selectedX ||
        oldDelegate.selectedY != selectedY;
  }
}

