// Terrain legend drawer for tile-map PNG export.
// SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_colors.dart' show terrainColorRgb;
import '../tile_map_topology_helpers.dart';
import 'tile_map_visualization_colors.dart' show seaColorRgb;
import 'tile_map_visualization_legend_layout.dart'
    show drawLegendLine, legendLineHeight, legendPadding;
import 'tile_map_visualization_legend_optional.dart'
    show drawLegendOptionalSectionsTrailer;

const int _tileMapLegendTitleLines = 2;

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
  var y = legendY0 + _tileMapLegendTitleLines * legendLineHeight;
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
  drawLegendOptionalSectionsTrailer(
    image: image,
    legendY0: legendY0,
    rowAfterPrimary: (y - legendY0) ~/ legendLineHeight,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    hasResourceGrid: result.resourceGrid != null,
  );
}
