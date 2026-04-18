// Fleet markers on debug / player-view maps when Units overlay is on.
// SPEC/program/ctdev-app-running-game.md.

import 'dart:math' as math;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Paints triangles for [fleets] in [region] (same toggle as army unit dots).
void paintFleetsForRegion(
  Canvas canvas,
  RegionMapViewData region,
  List<Fleet> fleets,
  double cellSize,
) {
  for (final f in fleets) {
    if (f.regionId != region.regionId) continue;
    final centroid = fleetCentroidCell(region, f);
    if (centroid == null) continue;
    final cx = centroid.$1 * cellSize + cellSize / 2;
    final cy = centroid.$2 * cellSize + cellSize / 2;
    final colorTuple =
        region.factionColors[f.ownerId] ?? (128, 128, 128);
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
    const r = 6.0;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx - r * 0.9, cy + r * 0.75)
      ..lineTo(cx + r * 0.9, cy + r * 0.75)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    final letter = _missionLetter(f.mission);
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: math.max(6, cellSize * 0.35),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        cx - textPainter.width / 2,
        cy - textPainter.height / 2 - 1,
      ),
    );
  }
}

String _missionLetter(FleetMission m) => switch (m) {
      FleetMission.none => '·',
      FleetMission.patrol => 'P',
      FleetMission.blockade => 'B',
      FleetMission.beachhead => 'H',
      FleetMission.defend => 'D',
    };

/// Cell coordinates (x, y) for fleet marker, or null if not placed.
(int, int)? fleetCentroidCell(RegionMapViewData region, Fleet fleet) {
  final sea = fleet.seaZoneId;
  if (sea != null) {
    var sx = 0;
    var sy = 0;
    var n = 0;
    for (final c in region.cells) {
      if (c.isSea && c.regionCellId == sea) {
        sx += c.x;
        sy += c.y;
        n++;
      }
    }
    if (n == 0) return null;
    return (sx ~/ n, sy ~/ n);
  }
  final port = fleet.inPortAtProvinceId;
  if (port == null) return null;
  final local = _localProvinceIdForRegion(port, fleet.regionId);
  if (local == null) return null;

  for (final pm in region.portMarkers) {
    if (_provinceIdsEqual(pm.provinceId, local)) {
      return (pm.x, pm.y);
    }
  }

  var sx = 0;
  var sy = 0;
  var n = 0;
  for (final c in region.cells) {
    if (c.isSea) continue;
    if (_provinceIdsEqual(c.regionCellId, local)) {
      sx += c.x;
      sy += c.y;
      n++;
    }
  }
  if (n == 0) return null;
  return (sx ~/ n, sy ~/ n);
}

String? _localProvinceIdForRegion(String prefixedOrLocal, String regionId) {
  final idx = prefixedOrLocal.indexOf('|');
  if (idx < 0) return prefixedOrLocal;
  final reg = prefixedOrLocal.substring(0, idx);
  if (reg != regionId) return null;
  return prefixedOrLocal.substring(idx + 1);
}

bool _provinceIdsEqual(String a, String b) =>
    a.toLowerCase() == b.toLowerCase();
