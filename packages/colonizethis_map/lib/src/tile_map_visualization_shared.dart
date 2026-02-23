// Shared helpers for tile map and game world state visualization.
// SPEC/program/map-visualization.md § Tile map visualizers, Legend layout abstraction.

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';

/// Legend layout constants. Shared by base and game-state visualizers.
const int legendPadding = 12;
const int legendLineHeight = 20;
const int swatchSize = 14;
const int swatchGap = 8;

/// Distinct RGB colors for region/faction assignment. Deterministic order.
const List<(int r, int g, int b)> regionPalette = [
  (180, 80, 80),   // red
  (80, 140, 200),  // blue
  (90, 160, 90),   // green
  (220, 180, 60),  // yellow
  (160, 100, 180), // purple
  (60, 180, 180),  // cyan
  (220, 140, 100), // orange
  (140, 100, 60),  // brown
  (200, 100, 160), // pink
  (100, 120, 200), // lighter blue
  (120, 200, 120), // light green
  (200, 200, 100), // light yellow
  (180, 140, 200), // light purple
  (100, 200, 200), // light cyan
  (200, 160, 140), // peach
  (160, 160, 160), // gray
];

/// Fixed RGB per terrain type for map fill and legend. Shared by base tile map visualizer and map view builder.
/// SPEC/program/map-visualization.md § Map view model for tools, Tile map PNG export.
const Map<TerrainType, (int r, int g, int b)> terrainColorRgb = {
  TerrainType.plains: (200, 220, 160),
  TerrainType.forest: (34, 100, 34),
  TerrainType.hills: (160, 130, 90),
  TerrainType.mountain: (120, 120, 120),
  TerrainType.swamp: (70, 100, 90),
  TerrainType.desert: (210, 190, 140),
};

/// Returns the single-letter legend glyph for a resource id (e.g. grain → 'g'), or null if unknown.
/// Matches SPEC/program/map-visualization.md legend; see SPEC/game/resource-terrain-region-rules.md.
String? resourceIdToLegendLetter(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) return null;
  switch (resourceId) {
    case 'grain':
      return 'g';
    case 'meat':
      return 'm';
    case 'wool':
      return 'w';
    case 'horses':
      return 'h';
    case 'timber':
      return 't';
    case 'iron':
      return 'i';
    case 'copper':
      return 'c';
    case 'tin':
      return 'n';
    case 'coal':
      return 'k';
    case 'sugarCane':
      return 's';
    case 'tobacco':
      return 'b';
    case 'cotton':
      return 'u';
    case 'furs':
      return 'f';
    case 'spices':
      return 'p';
    case 'silver':
      return 'v';
    case 'gold':
      return 'a';
    case 'gems':
      return 'e';
    case 'diamonds':
      return 'd';
    default:
      return null;
  }
}

/// Grey shades for minor nations (distinct from vibrant GP colours). Deterministic order.
const List<(int r, int g, int b)> minorNationPalette = [
  (70, 70, 70),
  (90, 90, 90),
  (110, 110, 110),
  (130, 130, 130),
  (150, 150, 150),
  (170, 170, 170),
  (190, 190, 190),
  (210, 210, 210),
];

/// Builds ownership colour map by faction type: GPs use GDD defaults (or [greatPowerColorOverride]), minors use [minorNationPalette], tribes use [regionPalette].
/// Insertion order: GPs first, then minor nations, then tribes (legend order).
Map<String, (int r, int g, int b)> factionOwnershipColorMap({
  List<String> greatPowerIds = const [],
  List<String> minorNationIds = const [],
  List<String> tribeIds = const [],
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
}) {
  final map = <String, (int r, int g, int b)>{};
  final gps = greatPowerIds.toList()..sort();
  final minors = minorNationIds.toList()..sort();
  final tribes = tribeIds.toList()..sort();
  for (var i = 0; i < gps.length; i++) {
    final id = gps[i];
    final override = greatPowerColorOverride?[id];
    final defaultColor = greatPowerDefaultColorRgb[id];
    map[id] = override ?? defaultColor ?? regionPalette[i % regionPalette.length];
  }
  for (var i = 0; i < minors.length; i++) {
    map[minors[i]] = minorNationPalette[i % minorNationPalette.length];
  }
  for (var i = 0; i < tribes.length; i++) {
    map[tribes[i]] = regionPalette[i % regionPalette.length];
  }
  return map;
}

/// Builds a map from region/faction id to (r, g, b) using deterministic palette.
Map<String, (int r, int g, int b)> colorMapFromIds(Iterable<String> ids) {
  final sorted = ids.toSet().toList()..sort();
  final map = <String, (int r, int g, int b)>{};
  for (var i = 0; i < sorted.length; i++) {
    map[sorted[i]] = regionPalette[i % regionPalette.length];
  }
  return map;
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
      final id = result.cell(x, y);
      if (x + 1 < result.width) {
        final other = result.cell(x + 1, y);
        if (id != other) {
          final borderColor =
              (seaZoneIds.contains(id) && seaZoneIds.contains(other))
                  ? seaZoneBorderColor
                  : black;
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
      }
      if (y + 1 < result.height) {
        final other = result.cell(x, y + 1);
        if (id != other) {
          final borderColor =
              (seaZoneIds.contains(id) && seaZoneIds.contains(other))
                  ? seaZoneBorderColor
                  : black;
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
      }
    }
  }
}

/// Land seed marker color (bright red).
const (int, int, int) landSeedMarkerRgb = (255, 0, 0);

/// Continent seed marker color (distinct from land seeds).
const (int, int, int) continentSeedMarkerRgb = (255, 255, 200);

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
