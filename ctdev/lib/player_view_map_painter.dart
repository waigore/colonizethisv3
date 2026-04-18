import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'debug_map_painter.dart';
import 'fleet_map_overlay.dart';

/// Builds the tile key for a cell in a region. Format: regionId|provinceId|x|y.
String tileKeyForCell(RegionMapViewData region, CellViewData cell) {
  return '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
}

/// Paints OW + NW map filtered by [PlayerView]: per-tile visibility (unknown/revealed/fogged/fullyVisible),
/// only the viewing player's units, capitals/ports only for fogged and fully visible provinces.
/// SPEC/program/ctdev-app.md § Per-player map.
class PlayerViewMapPainter extends CustomPainter {
  PlayerViewMapPainter({
    required this.viewData,
    required this.playerView,
    this.showOwnership = true,
    this.showCapitals = true,
    this.showPorts = true,
    this.geographicMode = false,
    this.showImprovements = false,
    this.showUnits = true,
    this.fleets = const [],
  });

  final InitGameMapViewData viewData;
  final PlayerView playerView;
  final bool showOwnership;
  final bool showCapitals;
  final bool showPorts;
  final bool geographicMode;
  final bool showImprovements;
  final bool showUnits;
  final List<Fleet> fleets;

  static const Color _unknownColor = Colors.black;
  static const Color _revealedColor = Color(0xFF606060);
  static const Color _seaColor = Color(0xFF003366);
  static const Color _landFallbackColor = Color(0xFF808080);
  static const Color _landBorderColor = Colors.black;
  static const Color _seaBorderColor = Color(0xFFADD8E6);
  static const Color _fogStripesColor = Color(0x50000000);

  @override
  void paint(Canvas canvas, Size size) {
    final ow = viewData.oldWorld;
    final nw = viewData.newWorld;
    final cellSize = ow.cellSize.toDouble() * kDebugMapScale;
    final gap = cellSize * 2;
    final owWidthPx = ow.width * cellSize;

    _paintRegion(
      canvas,
      ow,
      cellSize,
      Size(owWidthPx, ow.height * cellSize),
    );
    canvas.save();
    canvas.translate(owWidthPx + gap, 0);
    _paintRegion(
      canvas,
      nw,
      cellSize,
      Size(nw.width * cellSize, nw.height * cellSize),
    );
    canvas.restore();
  }

  void _paintRegion(
    Canvas canvas,
    RegionMapViewData region,
    double cellSize,
    Size size,
  ) {
    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (final cell in region.cells) {
      final tileKey = tileKeyForCell(region, cell);
      final vis = playerView.visibilityForTile(tileKey);
      final left = cell.x * cellSize;
      final top = cell.y * cellSize;
      final rect = Rect.fromLTWH(left, top, cellSize, cellSize);

      if (vis == VisibilityLevel.unknown) {
        fillPaint.color = _unknownColor;
        canvas.drawRect(rect, fillPaint);
        continue;
      }
      if (vis == VisibilityLevel.revealed) {
        fillPaint.color = _revealedColor;
        canvas.drawRect(rect, fillPaint);
        continue;
      }

      // fogged or fullyVisible: draw full colours
      if (cell.isSea) {
        fillPaint.color = _seaColor;
      } else if (geographicMode) {
        final terrain = cell.terrainType ??
            (cell.terrainTypeId != null
                ? TerrainType.values.byName(cell.terrainTypeId!)
                : null);
        final terrainRgb = terrain != null
            ? (region.terrainColors[terrain] ?? (128, 128, 128))
            : (128, 128, 128);
        fillPaint.color = Color.fromARGB(
          255,
          terrainRgb.$1,
          terrainRgb.$2,
          terrainRgb.$3,
        );
      } else if (!geographicMode && showOwnership) {
        final colorTuple =
            region.factionColors[cell.ownerFactionId] ?? (128, 128, 128);
        fillPaint.color = Color.fromARGB(
          255,
          colorTuple.$1,
          colorTuple.$2,
          colorTuple.$3,
        );
      } else {
        fillPaint.color = _landFallbackColor;
      }
      canvas.drawRect(rect, fillPaint);

      if (vis == VisibilityLevel.fogged) {
        _drawFogStripes(canvas, rect, cellSize);
      }
    }

    // Resource glyphs (geographic) only for fogged/fullyVisible
    if (geographicMode) {
      for (final cell in region.cells) {
        final vis = playerView.visibilityForTile(tileKeyForCell(region, cell));
        if (vis != VisibilityLevel.fogged && vis != VisibilityLevel.fullyVisible) {
          continue;
        }
        final visRes = resourceIdVisibleInPlayerView(
          playerView,
          tileKeyForCell(region, cell),
          cell.resourceId,
        );
        final letter = resourceIdToLegendLetter(visRes);
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
          Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
        );
      }
    }

    // Units: only viewing player's markers
    if (showUnits && region.unitMarkers.isNotEmpty) {
      for (final m in region.unitMarkers) {
        if (m.ownerFactionId != playerView.playerId) continue;
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

    if (showUnits && fleets.isNotEmpty) {
      final mine = fleets
          .where(
            (f) =>
                f.regionId == region.regionId && f.ownerId == playerView.playerId,
          )
          .toList();
      if (mine.isNotEmpty) {
        paintFleetsForRegion(canvas, region, mine, cellSize);
      }
    }

    // Improvements only for fogged/fullyVisible
    if (showImprovements) {
      for (final cell in region.cells) {
        if (cell.isSea) continue;
        final vis = playerView.visibilityForTile(tileKeyForCell(region, cell));
        if (vis != VisibilityLevel.fogged && vis != VisibilityLevel.fullyVisible) {
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

    // Borders between differing regionCellId neighbours
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

    // Ports: only when tile visibility is fogged or fullyVisible
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
        final cell = region.cellAt(port.x, port.y);
        final vis = playerView.visibilityForTile(tileKeyForCell(region, cell));
        if (vis != VisibilityLevel.fogged && vis != VisibilityLevel.fullyVisible) {
          continue;
        }
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

    // Capitals: only when tile visibility is fogged or fullyVisible
    if (showCapitals && region.capitalMarkers.isNotEmpty) {
      final capitalPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFD700);
      final capitalOutline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black;
      const radius = 6.0;
      for (final cap in region.capitalMarkers) {
        final cell = region.cellAt(cap.x, cap.y);
        final vis = playerView.visibilityForTile(tileKeyForCell(region, cell));
        if (vis != VisibilityLevel.fogged && vis != VisibilityLevel.fullyVisible) {
          continue;
        }
        final cx = cap.x * cellSize + cellSize / 2;
        final cy = cap.y * cellSize + cellSize / 2;
        final center = Offset(cx, cy);
        canvas.drawCircle(center, radius, capitalPaint);
        canvas.drawCircle(center, radius, capitalOutline);
      }
    }
  }

  void _drawFogStripes(Canvas canvas, Rect rect, double cellSize) {
    const stripeSpacing = 4.0;
    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _fogStripesColor;
    final left = rect.left;
    final top = rect.top;
    final w = rect.width;
    final h = rect.height;
    final diag = math.sqrt(w * w + h * h);
    final count = (diag / stripeSpacing).ceil() + 1;
    for (var i = -count; i <= count; i++) {
      final offset = i * stripeSpacing;
      canvas.drawLine(
        Offset(left + offset, top),
        Offset(left + offset + w, top + h),
        stripePaint,
      );
      canvas.drawLine(
        Offset(left, top + offset),
        Offset(left + w, top + offset + h),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlayerViewMapPainter oldDelegate) {
    return oldDelegate.viewData != viewData ||
        oldDelegate.playerView != playerView ||
        oldDelegate.showOwnership != showOwnership ||
        oldDelegate.showCapitals != showCapitals ||
        oldDelegate.showPorts != showPorts ||
        oldDelegate.geographicMode != geographicMode ||
        oldDelegate.showImprovements != showImprovements ||
        oldDelegate.showUnits != showUnits ||
        oldDelegate.fleets != fleets;
  }
}
