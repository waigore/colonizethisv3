// Region/province legend drawer for tile-map PNG export.
// SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import 'tile_map_visualization_legend_layout.dart'
    show drawLegendLine, legendLineHeight, legendPadding;
import 'tile_map_visualization_legend_optional.dart'
    show drawLegendOptionalSectionsTrailer;

const int _tileMapLegendTitleLines = 2;

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
  var y = legendY0 + _tileMapLegendTitleLines * legendLineHeight;
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
