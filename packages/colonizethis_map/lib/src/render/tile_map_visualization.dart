// Tile map to PNG with legend. SPEC/program/map-visualization.md § Tile map PNG export.

import 'dart:io';
import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import 'tile_map_visualization_colors.dart' show seaZoneBorderRgb;
import 'tile_map_visualization_legend.dart' show drawMapLegend, legendLineCount;
import 'tile_map_visualization_overlays.dart'
    show
        drawContinentSeedMarkers,
        drawLandSeedMarkers,
        drawMapCells,
        drawRegionIdLabels,
        drawResourceLettersOnMap,
        regionColorsForResult,
        seaZoneIdsForTopology;
import 'tile_map_visualization_shared.dart'
    show drawBorders, legendLineHeight, legendPadding;

export '../tile_map_image_viewer.dart' show openInDefaultViewer;
export 'tile_map_visualization_colors.dart';

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
  final seaZoneIds = seaZoneIdsForTopology(topology);

  final mapW = result.width * cellSize;
  final mapH = result.height * cellSize;
  final regionColors = regionColorsForResult(result, useTerrain: useTerrain);
  final legendLines = legendLineCount(
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

  drawMapCells(
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
    drawContinentSeedMarkers(
      image: image,
      continentSeedPositions: continentSeedPositions,
      cellSize: cellSize,
      black: black,
    );
  }

  if (showLandSeeds) {
    drawLandSeedMarkers(
      image: image,
      landSeedPositions: landSeedPositions,
      cellSize: cellSize,
      black: black,
      useLandSeedByContinent: useLandSeedByContinent,
      landSeedContinentIndices: landSeedContinentIndices,
    );
  }

  drawRegionIdLabels(image: image, result: result, cellSize: cellSize);

  if (result.resourceGrid != null) {
    drawResourceLettersOnMap(
      image: image,
      result: result,
      cellSize: cellSize,
      black: black,
    );
  }

  drawMapLegend(
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
