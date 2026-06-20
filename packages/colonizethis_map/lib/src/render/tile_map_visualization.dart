// Tile map to PNG with legend. SPEC/program/map-visualization.md § Tile map PNG export.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_grid.dart';
import '../tile_map_topology_helpers.dart';
import 'tile_map_visualization_shared.dart'
    show
        colorMapFromIds,
        continentSeedMarkerRgb,
        drawBorders,
        drawLegendContinentSeedMarker,
        drawLegendLandSeedMarker,
        drawLegendLine,
        drawResourceLegendRows,
        drawResourceLetterAtCellCenter,
        fillTileGridCells,
        landSeedMarkerRgb,
        legendLineHeight,
        legendPadding,
        regionPalette,
        swatchGap,
        swatchSize,
        terrainColorRgb,
        tileMapResourceGlyphs;
export '../tile_map_image_viewer.dart' show openInDefaultViewer;

/// Deep blue for sea zones. SPEC/program/map-visualization.md § Tile map PNG export.
const (int, int, int) seaColorRgb = (20, 60, 140);

/// Light blue for sea zone borders (sea–sea). SPEC/program/map-visualization.md § Tile map PNG export.
const (int, int, int) seaZoneBorderRgb = (173, 216, 230);

/// Red for on-map region id labels (e.g. p1, s1). SPEC/program/map-visualization.md § Tile map PNG export.
const (int, int, int) regionIdLabelRgb = (220, 0, 0);

const int _titleLines = 2;

/// Legend rows after the fixed title + primary swatch block (Refs #2489 D7).
int _optionalLegendSectionLineCount({
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  var rows = 0;
  if (showContinentSeeds) {
    rows++;
  }
  if (showLandSeeds) {
    if (useLandSeedByContinent && landSeedContinentIndices != null) {
      final maxContinent = landSeedContinentIndices.reduce(
        (a, b) => a > b ? a : b,
      );
      rows += maxContinent + 1;
    } else {
      rows++;
    }
  }
  if (hasResourceGrid) {
    rows += Resource.values.length;
  }
  return rows;
}

/// Draws optional legend sections (continent seeds, land seeds, resources). Returns updated row.
int _drawOptionalLegendSections(
  img.Image image,
  int legendY0,
  int row, {
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  final black = image.getColor(0, 0, 0);
  if (showContinentSeeds) {
    final y = legendY0 + row * legendLineHeight;
    drawLegendContinentSeedMarker(image, y);
    img.drawString(
      image,
      'Continent seeds (one per continent)',
      font: img.arial14,
      x: legendPadding + swatchSize + swatchGap,
      y: y,
      color: black,
    );
    row++;
  }
  if (showLandSeeds) {
    if (useLandSeedByContinent && landSeedContinentIndices != null) {
      final maxContinent = landSeedContinentIndices.reduce(
        (a, b) => a > b ? a : b,
      );
      for (var c = 0; c <= maxContinent; c++) {
        var y = legendY0 + row * legendLineHeight;
        final (r, g, b) = regionPalette[c % regionPalette.length];
        y = drawLegendLine(image, y, r, g, b, 'Continent $c');
        row = (y - legendY0) ~/ legendLineHeight;
      }
    } else {
      final y = legendY0 + row * legendLineHeight;
      drawLegendLandSeedMarker(image, y);
      img.drawString(
        image,
        'Land seeds (cluster per continent)',
        font: img.arial14,
        x: legendPadding + swatchSize + swatchGap,
        y: y,
        color: black,
      );
      row++;
    }
  }
  if (hasResourceGrid) {
    final yAfter = drawResourceLegendRows(
      image,
      legendY: legendY0 + row * legendLineHeight,
      textColor: black,
      resources: Resource.values,
    );
    row += (yAfter - (legendY0 + row * legendLineHeight)) ~/ legendLineHeight;
  }
  return row;
}

Iterable<String> _regionIdsFromResult(TileMapResult result) sync* {
  // ct-lint-allow: nested-grid-walk — sync* generator; a forEachIndex callback
  // cannot `yield` to the enclosing generator.
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      yield result.cell(x, y);
    }
  }
}

int _legendLineCount({
  required bool useTerrain,
  required MapTopology topology,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  final primaryLines = useTerrain
      ? _titleLines + 1 + TerrainType.values.length
      : _titleLines + topology.nodes.length;
  return primaryLines +
      _optionalLegendSectionLineCount(
        showContinentSeeds: showContinentSeeds,
        showLandSeeds: showLandSeeds,
        useLandSeedByContinent: useLandSeedByContinent,
        landSeedContinentIndices: landSeedContinentIndices,
        hasResourceGrid: hasResourceGrid,
      );
}

void _drawMapCells({
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
          ? _terrainOrSeaCellColor(result, seaZoneIds, x, y, id)
          : regionColors![id]!;
    },
  );
}

(int, int, int) _terrainOrSeaCellColor(
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

void _drawContinentSeedMarkers({
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

void _drawLandSeedMarkers({
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

void _drawRegionIdLabels({
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

void _drawResourceLettersOnMap({
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

void _drawMapLegend({
  required img.Image image,
  required TileMapResult result,
  required MapTopology topology,
  required int mapH,
  required img.Color black,
  required bool useTerrain,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
  required Map<String, (int, int, int)>? regionColors,
}) {
  final legendY0 = mapH + legendPadding;
  if (useTerrain) {
    _drawTerrainLegend(
      image: image,
      result: result,
      black: black,
      legendY0: legendY0,
      showContinentSeeds: showContinentSeeds,
      showLandSeeds: showLandSeeds,
      useLandSeedByContinent: useLandSeedByContinent,
      landSeedContinentIndices: landSeedContinentIndices,
    );
    return;
  }
  _drawRegionLegend(
    image: image,
    result: result,
    topology: topology,
    black: black,
    legendY0: legendY0,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    regionColors: regionColors!,
  );
}

void _drawTerrainLegend({
  required img.Image image,
  required TileMapResult result,
  required img.Color black,
  required int legendY0,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
}) {
  img.drawString(
    image,
    'Terrain. Black = land borders; light blue = sea zone borders.',
    font: img.arial14,
    x: legendPadding,
    y: legendY0,
    color: black,
  );
  img.drawString(
    image,
    'Colors = terrain type; sea = deep blue.',
    font: img.arial14,
    x: legendPadding,
    y: legendY0 + legendLineHeight,
    color: black,
  );
  var y = legendY0 + _titleLines * legendLineHeight;
  y = drawLegendLine(
    image,
    y,
    seaColorRgb.$1,
    seaColorRgb.$2,
    seaColorRgb.$3,
    'Sea',
  );
  for (final t in TerrainType.values) {
    final (r, g, b) = terrainColorRgb[t]!;
    y = drawLegendLine(image, y, r, g, b, _terrainLabel(t));
  }
  _drawOptionalLegendSections(
    image,
    legendY0,
    (y - legendY0) ~/ legendLineHeight,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    hasResourceGrid: result.resourceGrid != null,
  );
}

void _drawRegionLegend({
  required img.Image image,
  required TileMapResult result,
  required MapTopology topology,
  required img.Color black,
  required int legendY0,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
  required Map<String, (int, int, int)> regionColors,
}) {
  img.drawString(
    image,
    'Each cell = one tile. Colors = regions (provinces / sea zones).',
    font: img.arial14,
    x: legendPadding,
    y: legendY0,
    color: black,
  );
  img.drawString(
    image,
    'P = province (land), S = sea zone. Black = land borders; light blue = sea borders.',
    font: img.arial14,
    x: legendPadding,
    y: legendY0 + legendLineHeight,
    color: black,
  );
  final nodesSorted = List<TopologyNode>.from(topology.nodes)
    ..sort((a, b) => a.id.compareTo(b.id));
  var y = legendY0 + _titleLines * legendLineHeight;
  for (final n in nodesSorted) {
    final c = regionColors[n.id]!;
    y = drawLegendLine(
      image,
      y,
      c.$1,
      c.$2,
      c.$3,
      '${n.id} (${n.type == TopologyNodeType.province ? 'P' : 'S'})',
    );
  }
  _drawOptionalLegendSections(
    image,
    legendY0,
    (y - legendY0) ~/ legendLineHeight,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    hasResourceGrid: result.resourceGrid != null,
  );
}

/// Renders the tile map and legend to a PNG image; returns PNG bytes.
/// When [result.terrainGrid] is present: fill by terrain (sea = deep blue), draw province/sea borders in black, terrain legend. Otherwise: region-colored fill and region legend.
/// When [landSeedPositions] is provided, draws a marker at each cell center and adds a legend row for land seeds.
/// When [landSeedContinentIndices] is provided and same length as [landSeedPositions], land seeds are colored by continent and the legend lists one row per continent.
/// When [continentSeedPositions] is provided, draws a distinct marker at each and adds a legend row for continent seeds. SPEC/program/map-visualization.md § Tile map PNG export.
Uint8List renderTileMapToPng(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final useTerrain = result.terrainGrid != null;
  final showLandSeeds =
      landSeedPositions != null && landSeedPositions.isNotEmpty;
  final useLandSeedByContinent =
      showLandSeeds &&
      landSeedContinentIndices != null &&
      landSeedContinentIndices.length == landSeedPositions.length;
  final showContinentSeeds =
      continentSeedPositions != null && continentSeedPositions.isNotEmpty;
  final seaZoneIds = seaZoneIdsFromTopology(topology);

  final mapW = result.width * cellSize;
  final mapH = result.height * cellSize;
  final regionColors = useTerrain
      ? null
      : colorMapFromIds(_regionIdsFromResult(result));
  final legendLines = _legendLineCount(
    useTerrain: useTerrain,
    topology: topology,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    hasResourceGrid: result.resourceGrid != null,
  );
  final legendHeight = legendPadding * 2 + legendLines * legendLineHeight;
  final totalWidth = mapW;
  final totalHeight = mapH + legendHeight;

  final image = img.Image(width: totalWidth, height: totalHeight);
  final white = image.getColor(255, 255, 255);
  final black = image.getColor(0, 0, 0);
  final seaZoneBorderColor = image.getColor(
    seaZoneBorderRgb.$1,
    seaZoneBorderRgb.$2,
    seaZoneBorderRgb.$3,
  );
  image.clear(white);

  _drawMapCells(
    image: image,
    result: result,
    cellSize: cellSize,
    useTerrain: useTerrain,
    seaZoneIds: seaZoneIds,
    regionColors: regionColors,
  );

  // Borders: land borders (P–P, P–S) in black; sea zone borders (S–S) in light blue.
  drawBorders(image, result, seaZoneIds, cellSize, seaZoneBorderColor);

  if (showContinentSeeds) {
    _drawContinentSeedMarkers(
      image: image,
      continentSeedPositions: continentSeedPositions,
      cellSize: cellSize,
      black: black,
    );
  }

  if (showLandSeeds) {
    _drawLandSeedMarkers(
      image: image,
      landSeedPositions: landSeedPositions,
      cellSize: cellSize,
      black: black,
      useLandSeedByContinent: useLandSeedByContinent,
      landSeedContinentIndices: landSeedContinentIndices,
    );
  }

  _drawRegionIdLabels(image: image, result: result, cellSize: cellSize);

  if (result.resourceGrid != null) {
    _drawResourceLettersOnMap(
      image: image,
      result: result,
      cellSize: cellSize,
      black: black,
    );
  }

  _drawMapLegend(
    image: image,
    result: result,
    topology: topology,
    mapH: mapH,
    black: black,
    useTerrain: useTerrain,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    regionColors: regionColors,
  );

  return img.encodePng(image);
}

String _terrainLabel(TerrainType t) {
  switch (t) {
    case TerrainType.plains:
      return 'Plains';
    case TerrainType.forest:
      return 'Forest';
    case TerrainType.hills:
      return 'Hills';
    case TerrainType.mountain:
      return 'Mountain';
    case TerrainType.swamp:
      return 'Swamp';
    case TerrainType.desert:
      return 'Desert';
  }
}

/// Writes the tile map image to [file].
void writeTileMapImageToFile(
  File file,
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final png = renderTileMapToPng(
    result,
    topology,
    cellSize: cellSize,
    landSeedPositions: landSeedPositions,
    landSeedContinentIndices: landSeedContinentIndices,
    continentSeedPositions: continentSeedPositions,
  );
  file.writeAsBytesSync(png);
}

/// Writes the tile map image to a new file in the system temp directory.
/// Returns the absolute path of the written file.
String writeTileMapImageToTempFile(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final tmp = Directory.systemTemp;
  final name = 'tile_map_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${tmp.path}/$name');
  writeTileMapImageToFile(
    file,
    result,
    topology,
    cellSize: cellSize,
    landSeedPositions: landSeedPositions,
    landSeedContinentIndices: landSeedContinentIndices,
    continentSeedPositions: continentSeedPositions,
  );
  return file.absolute.path;
}
