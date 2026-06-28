// Shared resource legend and glyph helpers for map visualizers.
// SPEC/program/map-visualization.md § Legend layout abstraction.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../view/init_game_map_view_data.dart';

/// Single-letter legend glyph for a resource (e.g. grain -> 'g').
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

/// Display label for a resource in the legend (e.g. grain -> 'Grain').
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

/// Returns the single-letter legend glyph for a resource id, or null if unknown.
String? resourceIdToLegendLetter(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) return null;
  try {
    return resourceToLegendLetter(Resource.values.byName(resourceId));
  } on ArgumentError {
    return null;
  }
}

/// Resources shown as glyphs and legend rows in game-world geographic PNG.
const List<Resource> geographicGameWorldLegendResources = [
  Resource.grain,
  Resource.timber,
  Resource.iron,
];

/// Single-letter glyph for [resourceId] in geographic game-world map mode.
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
  // ct-lint-allow: nested-grid-walk — sync* generator; a forEachIndex callback
  // cannot `yield` to the enclosing generator.
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

/// Draws a single-letter resource glyph at cell centre.
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
