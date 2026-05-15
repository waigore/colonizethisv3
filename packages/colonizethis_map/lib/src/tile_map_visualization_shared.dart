// Shared helpers for tile map and game world state visualization.
// SPEC/program/map-visualization.md § Tile map visualizers, Legend layout abstraction.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import 'init_game_map_view_data.dart';
import 'tile_map_colors.dart';

export 'tile_map_colors.dart';
export 'tile_map_resource_legend.dart';

/// Legend layout constants. Shared by base and game-state visualizers.
const int legendPadding = 12;
const int legendLineHeight = 20;
const int swatchSize = 14;
const int swatchGap = 8;

/// Title line for PNG game-world ownership overlays (combined and view-data paths).
/// SPEC/program/map-visualization.md § Game world state map visualizer.
const String kGameWorldMapOwnershipLegendBlurb =
    'Ownership by faction. Black = land borders; light blue = sea borders.';

/// Sea-zone local ids from flattened [RegionMapViewData] cells.
///
/// Use when rendering from view data without a [MapTopology] (dual with
/// [seaZoneIdsFromTopology]). Order is not preserved; ids are unique.
Set<String> seaZoneLocalIdsFromRegionCells(List<CellViewData> cells) {
  final out = <String>{};
  for (final cell in cells) {
    if (cell.isSea) {
      out.add(cell.regionCellId);
    }
  }
  return out;
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
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
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
    }
  }
}

/// Draws a color swatch in the legend at row y.
void drawLegendSwatch(img.Image image, int y, int r, int g, int b) {
  final color = image.getColor(r, g, b);
  img.fillRect(
    image,
    x1: legendPadding,
    y1: y,
    x2: legendPadding + swatchSize,
    y2: y + swatchSize,
    color: color,
  );
}

/// Draws a continent seed marker in the legend (larger circle).
void drawLegendContinentSeedMarker(img.Image image, int y) {
  final cx = legendPadding + swatchSize ~/ 2;
  final cy = y + swatchSize ~/ 2;
  final fillColor = image.getColor(
    continentSeedMarkerRgb.$1,
    continentSeedMarkerRgb.$2,
    continentSeedMarkerRgb.$3,
  );
  final black = image.getColor(0, 0, 0);
  img.fillCircle(image, x: cx, y: cy, radius: 5, color: fillColor);
  img.drawCircle(image, x: cx, y: cy, radius: 5, color: black);
}

/// Draws a land seed marker in the legend (smaller circle).
void drawLegendLandSeedMarker(img.Image image, int y) {
  final cx = legendPadding + swatchSize ~/ 2;
  final cy = y + swatchSize ~/ 2;
  final black = image.getColor(0, 0, 0);
  final color = image.getColor(
    landSeedMarkerRgb.$1,
    landSeedMarkerRgb.$2,
    landSeedMarkerRgb.$3,
  );
  img.fillCircle(image, x: cx, y: cy, radius: 4, color: color);
  img.drawCircle(image, x: cx, y: cy, radius: 4, color: black);
}

// --- Game world state map visualizer: shared marker and legend helpers ---
// SPEC/program/map-visualization.md § Game world state map visualizer.

/// Capital marker color (gold), distinct from terrain. Used for drawing and legend.
const (int, int, int) capitalMarkerRgb = (255, 215, 0);

/// Port marker color (teal), distinct from capitals.
const (int, int, int) portMarkerRgb = (0, 100, 140);

/// Draws port markers (filled teal square with black outline) at cell centres.
/// Call after fill and borders, before capital markers.
void drawPortMarkersOnImage(
  img.Image image,
  Iterable<({int x, int y})> portTiles,
  int cellSize,
) {
  const portHalfSize = 4;
  final black = image.getColor(0, 0, 0);
  final portColor = image.getColor(
    portMarkerRgb.$1,
    portMarkerRgb.$2,
    portMarkerRgb.$3,
  );
  for (final pt in portTiles) {
    final cx = pt.x * cellSize + cellSize ~/ 2;
    final cy = pt.y * cellSize + cellSize ~/ 2;
    img.fillRect(
      image,
      x1: cx - portHalfSize,
      y1: cy - portHalfSize,
      x2: cx + portHalfSize,
      y2: cy + portHalfSize,
      color: portColor,
    );
    img.drawRect(
      image,
      x1: cx - portHalfSize,
      y1: cy - portHalfSize,
      x2: cx + portHalfSize,
      y2: cy + portHalfSize,
      color: black,
    );
  }
}

/// Draws capital markers (filled gold circle with black outline) at cell centres.
void drawCapitalMarkersOnImage(
  img.Image image,
  Iterable<({int x, int y})> positions,
  int cellSize,
) {
  const capitalRadius = 6;
  final black = image.getColor(0, 0, 0);
  final capitalColor = image.getColor(
    capitalMarkerRgb.$1,
    capitalMarkerRgb.$2,
    capitalMarkerRgb.$3,
  );
  for (final pos in positions) {
    final cx = pos.x * cellSize + cellSize ~/ 2;
    final cy = pos.y * cellSize + cellSize ~/ 2;
    img.fillCircle(
      image,
      x: cx,
      y: cy,
      radius: capitalRadius,
      color: capitalColor,
    );
    img.drawCircle(image, x: cx, y: cy, radius: capitalRadius, color: black);
  }
}

/// Draws one legend line: swatch (r,g,b) + label at [y]. Returns y + legendLineHeight.
int drawLegendLine(img.Image image, int y, int r, int g, int b, String label) {
  drawLegendSwatch(image, y, r, g, b);
  final black = image.getColor(0, 0, 0);
  img.drawString(
    image,
    label,
    font: img.arial14,
    x: legendPadding + swatchSize + swatchGap,
    y: y,
    color: black,
  );
  return y + legendLineHeight;
}

/// Draws the "Ports marked with teal square." legend line at [y]. Returns y + legendLineHeight.
int drawPortsLegendLine(img.Image image, int y) {
  final black = image.getColor(0, 0, 0);
  img.drawString(
    image,
    'Ports marked with teal square.',
    font: img.arial14,
    x: legendPadding,
    y: y,
    color: black,
  );
  return y + legendLineHeight;
}
