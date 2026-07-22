// Shared cell-fill and border primitives for tile-map PNG export.
// SPEC/program/map-visualization.md § Cell-fill render pipeline.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_grid.dart';
import '../view/init_game_map_view_data.dart';

/// Fills the [cellSize]×[cellSize] pixel block for tile cell ([cellX],[cellY])
/// with [color].
///
/// Single source of truth for the per-cell rectangle geometry shared by every
/// PNG fill path (terrain, region, and ownership). Keeping the
/// `x1/y1/x2/y2` math in one place guarantees the three render paths produce
/// byte-identical fills and differ only by their colour strategy
/// (Refs #3574 render-pipeline dedup).
void fillCellRect(
  img.Image image, {
  required int cellX,
  required int cellY,
  required int cellSize,
  required img.Color color,
}) {
  img.fillRect(
    image,
    x1: cellX * cellSize,
    y1: cellY * cellSize,
    x2: (cellX + 1) * cellSize - 1,
    y2: (cellY + 1) * cellSize - 1,
    color: color,
  );
}

/// Fills every cell of a [height] rows × [width] columns tile grid using the
/// RGB colour returned by [colorAt] for cell `(x, y)`.
///
/// Iteration routes through [TileMapGrid.forEachIndex] (the canonical row-major
/// walk) so fill order matches the borders/markers drawn afterwards and stays
/// bit-for-bit deterministic. The geographic/region/ownership PNG paths differ
/// only by the [colorAt] **fill strategy**, not by a copy-pasted double loop
/// (Refs #3574).
void fillTileGridCells(
  img.Image image, {
  required int height,
  required int width,
  required int cellSize,
  required (int r, int g, int b) Function(int x, int y) colorAt,
}) {
  TileMapGrid.forEachIndex(height, width, (y, x) {
    final (r, g, b) = colorAt(x, y);
    fillCellRect(
      image,
      cellX: x,
      cellY: y,
      cellSize: cellSize,
      color: image.getColor(r, g, b),
    );
  });
}

/// Fills each cell in [cells] (flattened [CellViewData] from a
/// [RegionMapViewData]) using the RGB colour returned by [colorAt].
///
/// View-data render paths walk a pre-flattened cell list rather than a 2D grid,
/// so this companion of [fillTileGridCells] shares the same [fillCellRect]
/// primitive and lets political vs geographic view-data fills differ only by
/// the [colorAt] strategy (Refs #3574).
void fillRegionViewCells(
  img.Image image, {
  required Iterable<CellViewData> cells,
  required int cellSize,
  required (int r, int g, int b) Function(CellViewData cell) colorAt,
}) {
  for (final cell in cells) {
    final (r, g, b) = colorAt(cell);
    fillCellRect(
      image,
      cellX: cell.x,
      cellY: cell.y,
      cellSize: cellSize,
      color: image.getColor(r, g, b),
    );
  }
}

img.Color _borderColorForAdjacentCells(
  String id,
  String other,
  Set<String> seaZoneIds,
  img.Color seaZoneBorderColor,
  img.Color black,
) {
  if (seaZoneIds.contains(id) && seaZoneIds.contains(other)) {
    return seaZoneBorderColor;
  }
  return black;
}

void _drawVerticalCellBorderIfDifferent(
  img.Image image,
  TileMapResult result,
  int x,
  int y,
  Set<String> seaZoneIds,
  int cellSize,
  img.Color seaZoneBorderColor,
  img.Color black,
  int borderThickness,
) {
  final id = result.cell(x, y);
  final other = result.cell(x + 1, y);
  if (id == other) return;
  final borderColor = _borderColorForAdjacentCells(
    id,
    other,
    seaZoneIds,
    seaZoneBorderColor,
    black,
  );
  final xEdge = (x + 1) * cellSize;
  img.drawLine(
    image,
    x1: xEdge,
    y1: y * cellSize,
    x2: xEdge,
    y2: (y + 1) * cellSize - 1,
    color: borderColor,
    thickness: borderThickness,
  );
}

void _drawHorizontalCellBorderIfDifferent(
  img.Image image,
  TileMapResult result,
  int x,
  int y,
  Set<String> seaZoneIds,
  int cellSize,
  img.Color seaZoneBorderColor,
  img.Color black,
  int borderThickness,
) {
  final id = result.cell(x, y);
  final other = result.cell(x, y + 1);
  if (id == other) return;
  final borderColor = _borderColorForAdjacentCells(
    id,
    other,
    seaZoneIds,
    seaZoneBorderColor,
    black,
  );
  final yEdge = (y + 1) * cellSize;
  img.drawLine(
    image,
    x1: x * cellSize,
    y1: yEdge,
    x2: (x + 1) * cellSize - 1,
    y2: yEdge,
    color: borderColor,
    thickness: borderThickness,
  );
}

/// Draws borders between regions: land borders in black, sea zone borders in [seaZoneBorderColor].
void drawBorders(
  img.Image image,
  TileMapResult result,
  Set<String> seaZoneIds,
  int cellSize,
  img.Color seaZoneBorderColor,
) {
  final black = image.getColor(0, 0, 0);
  final borderThickness = cellSize >= 12 ? 2 : 1;
  TileMapGrid.forEachIndex(result.height, result.width, (y, x) {
    if (x + 1 < result.width) {
      _drawVerticalCellBorderIfDifferent(
        image,
        result,
        x,
        y,
        seaZoneIds,
        cellSize,
        seaZoneBorderColor,
        black,
        borderThickness,
      );
    }
    if (y + 1 < result.height) {
      _drawHorizontalCellBorderIfDifferent(
        image,
        result,
        x,
        y,
        seaZoneIds,
        cellSize,
        seaZoneBorderColor,
        black,
        borderThickness,
      );
    }
  });
}
