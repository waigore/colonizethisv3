import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';
import 'package:image/image.dart' as img;

import 'support/init_game_map_view_fixtures.dart';

/// Shared fixtures for the `tile_map_visualization` test suites.
///
/// These were split out of the former single `tile_map_visualization_test.dart`
/// so that the render and helper test files each stay under the 500-line
/// guideline without duplicating the topology/result fixtures. Refs #3588, #3846.
final MapTopology visualizationTopology =
    oldWorldTwoProvinceSeaVisualizationTopology();

final TileMapResult visualizationSmallResult = visualizationSmallTileMap();

/// Result with terrain: p1/p2 land, s1 sea; at least one horizontal and one
/// vertical border.
final TileMapResult visualizationResultWithTerrain = mapTileGrid(
  [
    ['p1', 'p1', 'p2', 'p2'],
    ['p1', 's1', 's1', 'p2'],
    ['p1', 'p1', 'p2', 'p2'],
  ],
  terrainGrid: [
    [
      TerrainType.plains,
      TerrainType.plains,
      TerrainType.hills,
      TerrainType.hills,
    ],
    [TerrainType.plains, null, null, TerrainType.hills],
    [
      TerrainType.plains,
      TerrainType.plains,
      TerrainType.hills,
      TerrainType.hills,
    ],
  ],
);

/// Like [visualizationResultWithTerrain] with resourceGrid:
/// (0,0)=grain, (2,0)=timber, (0,2)=iron; others null.
final TileMapResult visualizationResultWithTerrainAndResources = mapTileGrid(
  visualizationResultWithTerrain.grid,
  terrainGrid: visualizationResultWithTerrain.terrainGrid,
  resourceGrid: [
    [Resource.grain, null, Resource.timber, null],
    [null, null, null, null],
    [Resource.iron, null, null, null],
  ],
);

/// Sea color and plains color from tile_map_visualization (for pixel assertions).
const (int, int, int) visualizationSeaRgb = (20, 60, 140);
const (int, int, int) visualizationPlainsRgb = (200, 220, 160);
const (int, int, int) visualizationSeaZoneBorderRgb = (173, 216, 230);
const int visualizationColorTolerance = 2;

img.Image decodeRenderedPng(List<int> bytes) {
  final decoded = img.decodeImage(Uint8List.fromList(bytes));
  expect(decoded, isNotNull);
  return decoded!;
}

(int, int) cellCenterPixel(int col, int row, int cellSize) =>
    (col * cellSize + cellSize ~/ 2, row * cellSize + cellSize ~/ 2);

void expectPixelNearRgb(
  img.Image image,
  int x,
  int y,
  (int, int, int) rgb, {
  int tolerance = visualizationColorTolerance,
}) {
  final pixel = image.getPixel(x, y);
  expect((pixel.r - rgb.$1).abs(), lessThanOrEqualTo(tolerance));
  expect((pixel.g - rgb.$2).abs(), lessThanOrEqualTo(tolerance));
  expect((pixel.b - rgb.$3).abs(), lessThanOrEqualTo(tolerance));
}

List<int> renderTileMapPngBytes(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 8,
  List<(int, int)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int, int)>? continentSeedPositions,
}) =>
    renderTileMapToPng(
      result,
      topology,
      cellSize: cellSize,
      landSeedPositions: landSeedPositions,
      landSeedContinentIndices: landSeedContinentIndices,
      continentSeedPositions: continentSeedPositions,
    );

img.Image decodeRenderTileMapToPng(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 8,
  List<(int, int)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int, int)>? continentSeedPositions,
}) =>
    decodeRenderedPng(
      renderTileMapPngBytes(
        result,
        topology,
        cellSize: cellSize,
        landSeedPositions: landSeedPositions,
        landSeedContinentIndices: landSeedContinentIndices,
        continentSeedPositions: continentSeedPositions,
      ),
    );
