import 'package:colonizethis_data/colonizethis_data.dart';

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
