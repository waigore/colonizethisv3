// On-map overlay draws for tile-map PNG export. SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_grid.dart';
import '../tile_map_topology_helpers.dart';
import 'tile_map_visualization_shared.dart'
    show
        colorMapFromIds,
        continentSeedMarkerRgb,
        drawResourceLetterAtCellCenter,
        fillTileGridCells,
        landSeedMarkerRgb,
        regionPalette,
        terrainColorRgb,
        tileMapResourceGlyphs;
import 'tile_map_visualization_colors.dart' show regionIdLabelRgb, seaColorRgb;

void drawMapCells({
  required img.Image image,
  required TileMapResult result,
  required int cellSize,
  required bool useTerrain,
  required Set<String> seaZoneIds,
  required Map<String, (int, int, int)>? regionColors,
}) {
  fillTileGridCells(
    image,
    height: result.height,
    width: result.width,
    cellSize: cellSize,
    colorAt: (x, y) {
      final id = result.cell(x, y);
      return useTerrain
          ? terrainOrSeaCellColor(result, seaZoneIds, x, y, id)
          : regionColors![id]!;
    },
  );
}

(int, int, int) terrainOrSeaCellColor(
  TileMapResult result,
  Set<String> seaZoneIds,
  int x,
  int y,
  String id,
) {
  final terrain = result.terrainAt(x, y);
  if (seaZoneIds.contains(id) || terrain == null) {
    return seaColorRgb;
  }
  return terrainColorRgb[terrain]!;
}

Iterable<String> regionIdsFromResult(TileMapResult result) sync* {
  // ct-lint-allow: nested-grid-walk — sync* generator; a forEachIndex callback
  // cannot `yield` to the enclosing generator.
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      yield result.cell(x, y);
    }
  }
}

Map<String, (int, int, int)>? regionColorsForResult(
  TileMapResult result, {
  required bool useTerrain,
}) {
  return useTerrain ? null : colorMapFromIds(regionIdsFromResult(result));
}

void drawContinentSeedMarkers({
  required img.Image image,
  required List<(int x, int y)> continentSeedPositions,
  required int cellSize,
  required img.Color black,
}) {
  const radius = 5;
  final fillColor = image.getColor(
    continentSeedMarkerRgb.$1,
    continentSeedMarkerRgb.$2,
    continentSeedMarkerRgb.$3,
  );
  for (final (sx, sy) in continentSeedPositions) {
    final cx = sx * cellSize + cellSize ~/ 2;
    final cy = sy * cellSize + cellSize ~/ 2;
    img.fillCircle(image, x: cx, y: cy, radius: radius, color: fillColor);
    img.drawCircle(image, x: cx, y: cy, radius: radius, color: black);
  }
}

void drawLandSeedMarkers({
  required img.Image image,
  required List<(int x, int y)> landSeedPositions,
  required int cellSize,
  required img.Color black,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
}) {
  const radius = 3;
  for (var i = 0; i < landSeedPositions.length; i++) {
    final (sx, sy) = landSeedPositions[i];
    final (r, g, b) = useLandSeedByContinent
        ? regionPalette[landSeedContinentIndices![i] % regionPalette.length]
        : landSeedMarkerRgb;
    final cx = sx * cellSize + cellSize ~/ 2;
    final cy = sy * cellSize + cellSize ~/ 2;
    img.fillCircle(
      image,
      x: cx,
      y: cy,
      radius: radius,
      color: image.getColor(r, g, b),
    );
    img.drawCircle(image, x: cx, y: cy, radius: radius, color: black);
  }
}

void drawRegionIdLabels({
  required img.Image image,
  required TileMapResult result,
  required int cellSize,
}) {
  final regionIdColor = image.getColor(
    regionIdLabelRgb.$1,
    regionIdLabelRgb.$2,
    regionIdLabelRgb.$3,
  );
  const idInset = 2;
  TileMapGrid.forEachIndex(result.height, result.width, (y, x) {
    final id = result.cell(x, y);
    img.drawString(
      image,
      id,
      font: img.arial14,
      x: x * cellSize + idInset,
      y: y * cellSize + idInset,
      color: regionIdColor,
    );
  });
}

void drawResourceLettersOnMap({
  required img.Image image,
  required TileMapResult result,
  required int cellSize,
  required img.Color black,
}) {
  for (final glyph in tileMapResourceGlyphs(result)) {
    drawResourceLetterAtCellCenter(
      image,
      letter: glyph.letter,
      cellX: glyph.x,
      cellY: glyph.y,
      cellSize: cellSize,
      color: black,
    );
  }
}

Set<String> seaZoneIdsForTopology(MapTopology topology) =>
    seaZoneIdsFromTopology(topology);
