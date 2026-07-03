// Legend layout for tile-map PNG export. SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_topology_helpers.dart';
import 'tile_map_visualization_shared.dart'
    show
        drawLegendContinentSeedMarker,
        drawLegendLandSeedMarker,
        drawLegendLine,
        drawResourceLegendRows,
        legendLineHeight,
        legendPadding,
        regionPalette,
        swatchGap,
        swatchSize,
        terrainColorRgb;
import 'tile_map_visualization_colors.dart' show seaColorRgb;

const int tileMapLegendTitleLines = 2;

/// Legend rows after the fixed title + primary swatch block (Refs #2489 D7).
int optionalLegendSectionLineCount({
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

/// Draws optional legend sections (continent seeds, land seeds, resources).
int drawOptionalLegendSections(
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

int legendLineCount({
  required bool useTerrain,
  required MapTopology topology,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  final primaryLines = useTerrain
      ? tileMapLegendTitleLines + 1 + TerrainType.values.length
      : tileMapLegendTitleLines + topology.nodes.length;
  return primaryLines +
      optionalLegendSectionLineCount(
        showContinentSeeds: showContinentSeeds,
        showLandSeeds: showLandSeeds,
        useLandSeedByContinent: useLandSeedByContinent,
        landSeedContinentIndices: landSeedContinentIndices,
        hasResourceGrid: hasResourceGrid,
      );
}

void drawMapLegend({
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
    drawTerrainLegend(
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
  drawRegionLegend(
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

void drawTerrainLegend({
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
  var y = legendY0 + tileMapLegendTitleLines * legendLineHeight;
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
    y = drawLegendLine(image, y, r, g, b, terrainDisplayName(t));
  }
  drawOptionalLegendSections(
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

void drawRegionLegend({
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
  var y = legendY0 + tileMapLegendTitleLines * legendLineHeight;
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
  drawOptionalLegendSections(
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
