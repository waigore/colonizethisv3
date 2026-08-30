// Legend layout for tile-map PNG export. SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import 'tile_map_visualization_legend_layout.dart' show legendPadding;
import 'tile_map_visualization_legend_optional.dart'
    show optionalLegendSectionLineCount;
import 'tile_map_visualization_legend_region.dart' show drawRegionLegend;
import 'tile_map_visualization_legend_terrain.dart' show drawTerrainLegend;

const int tileMapLegendTitleLines = 2;

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
