import 'package:flutter/material.dart';

/// Start and end [Offset]s for the warp-zone glow segment on the shared edge
/// between cell `(x, y)` and neighbor `(x + dx, y + dy)`.
///
/// [dx]/[dy] must be a cardinal direction: `(±1, 0)` or `(0, ±1)`.
/// Coordinates match the historical map math: vertical edges at
/// `(x + 1) * cellSize` for east, `x * cellSize` for west; horizontal edges at
/// `(y + 1) * cellSize` for south, `y * cellSize` for north.
(Offset start, Offset end) warpZoneGlowLineForDirection({
  required double cellSize,
  required int x,
  required int y,
  required int dx,
  required int dy,
}) {
  if (dx == 1 && dy == 0) {
    final xEdge = (x + 1) * cellSize;
    return (Offset(xEdge, y * cellSize), Offset(xEdge, (y + 1) * cellSize));
  }
  if (dx == -1 && dy == 0) {
    final xEdge = x * cellSize;
    return (Offset(xEdge, y * cellSize), Offset(xEdge, (y + 1) * cellSize));
  }
  if (dx == 0 && dy == 1) {
    final yEdge = (y + 1) * cellSize;
    return (Offset(x * cellSize, yEdge), Offset((x + 1) * cellSize, yEdge));
  }
  if (dx == 0 && dy == -1) {
    final yEdge = y * cellSize;
    return (Offset(x * cellSize, yEdge), Offset((x + 1) * cellSize, yEdge));
  }
  throw StateError(
    'warpZoneGlowLineForDirection: expected cardinal (dx,dy), got ($dx,$dy)',
  );
}
