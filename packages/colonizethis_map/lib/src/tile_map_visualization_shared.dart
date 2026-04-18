// Shared helpers for tile map and game world state visualization.
// SPEC/program/map-visualization.md § Tile map visualizers, Legend layout abstraction.

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';

import 'init_game_map_view_data.dart';

/// Legend layout constants. Shared by base and game-state visualizers.
const int legendPadding = 12;
const int legendLineHeight = 20;
const int swatchSize = 14;
const int swatchGap = 8;

/// Distinct RGB colors for region/faction assignment. Deterministic order.
const List<(int r, int g, int b)> regionPalette = [
  (180, 80, 80), // red
  (80, 140, 200), // blue
  (90, 160, 90), // green
  (220, 180, 60), // yellow
  (160, 100, 180), // purple
  (60, 180, 180), // cyan
  (220, 140, 100), // orange
  (140, 100, 60), // brown
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

/// Single-letter legend glyph for a resource (e.g. grain → 'g').
/// Matches SPEC/program/map-visualization.md legend; see SPEC/game/resource-terrain-region-rules.md.
String resourceToLegendLetter(Resource r) {
  switch (r) {
    case Resource.grain:
      return 'g';
    case Resource.meat:
      return 'm';
    case Resource.wool:
      return 'w';
    case Resource.horses:
      return 'h';
    case Resource.timber:
      return 't';
    case Resource.iron:
      return 'i';
    case Resource.copper:
      return 'c';
    case Resource.tin:
      return 'n';
    case Resource.coal:
      return 'k';
    case Resource.sugarCane:
      return 's';
    case Resource.tobacco:
      return 'b';
    case Resource.cotton:
      return 'u';
    case Resource.furs:
      return 'f';
    case Resource.spices:
      return 'p';
    case Resource.silver:
      return 'v';
    case Resource.gold:
      return 'a';
    case Resource.gems:
      return 'e';
    case Resource.diamonds:
      return 'd';
  }
}

/// Display label for a resource in the legend (e.g. grain → 'Grain').
String resourceToLegendLabel(Resource r) {
  switch (r) {
    case Resource.grain:
      return 'Grain';
    case Resource.meat:
      return 'Meat';
    case Resource.wool:
      return 'Wool';
    case Resource.horses:
      return 'Horses';
    case Resource.timber:
      return 'Timber';
    case Resource.iron:
      return 'Iron';
    case Resource.copper:
      return 'Copper';
    case Resource.tin:
      return 'Tin';
    case Resource.coal:
      return 'Coal';
    case Resource.sugarCane:
      return 'Sugar Cane';
    case Resource.tobacco:
      return 'Tobacco';
    case Resource.cotton:
      return 'Cotton';
    case Resource.furs:
      return 'Furs';
    case Resource.spices:
      return 'Spices';
    case Resource.silver:
      return 'Silver';
    case Resource.gold:
      return 'Gold';
    case Resource.gems:
      return 'Gems';
    case Resource.diamonds:
      return 'Diamonds';
  }
}

/// Returns the single-letter legend glyph for a resource id (e.g. grain → 'g'), or null if unknown.
/// Matches SPEC/program/map-visualization.md legend; see SPEC/game/resource-terrain-region-rules.md.
String? resourceIdToLegendLetter(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) return null;
  try {
    return resourceToLegendLetter(Resource.values.byName(resourceId));
  } on ArgumentError {
    return null;
  }
}

/// Resources shown as glyphs and legend rows in game-world geographic PNG (view-data path only).
/// SPEC/program/map-visualization.md § Geographic legend scope (subset g, t, i).
const List<Resource> geographicGameWorldLegendResources = [
  Resource.grain,
  Resource.timber,
  Resource.iron,
];

/// Single-letter glyph for [resourceId] in geographic game-world map mode, or null if not in the g/t/i subset or unknown id.
String? geographicGameWorldResourceGlyphLetter(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) return null;
  try {
    final r = Resource.values.byName(resourceId);
    switch (r) {
      case Resource.grain:
      case Resource.timber:
      case Resource.iron:
        return resourceToLegendLetter(r);
      default:
        return null;
    }
  } on ArgumentError {
    return null;
  }
}

/// Returns tile positions + glyph letters for non-null tile-map resources.
Iterable<({int x, int y, String letter})> tileMapResourceGlyphs(
  TileMapResult result,
) sync* {
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final resource = result.resourceAt(x, y);
      if (resource == null) continue;
      yield (x: x, y: y, letter: resourceToLegendLetter(resource));
    }
  }
}

/// Returns cell positions + glyph letters for valid geographic game-world resources.
Iterable<({int x, int y, String letter})> geographicGameWorldResourceGlyphs(
  Iterable<CellViewData> cells,
) sync* {
  for (final cell in cells) {
    final letter = geographicGameWorldResourceGlyphLetter(cell.resourceId);
    if (letter == null) continue;
    yield (x: cell.x, y: cell.y, letter: letter);
  }
}

/// Draws a single-letter resource glyph at cell centre (PNG map export). Shared by tile map and game-world geographic renderers.
void drawResourceLetterAtCellCenter(
  img.Image image, {
  required String letter,
  required int cellX,
  required int cellY,
  required int cellSize,
  required img.Color color,
  int offsetX = 4,
  int offsetY = 7,
}) {
  final cx = cellX * cellSize + cellSize ~/ 2;
  final cy = cellY * cellSize + cellSize ~/ 2;
  img.drawString(
    image,
    letter,
    font: img.arial14,
    x: cx - offsetX,
    y: cy - offsetY,
    color: color,
  );
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
    map[id] =
        override ?? defaultColor ?? regionPalette[i % regionPalette.length];
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
