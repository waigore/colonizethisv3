/// Grid and connectivity helpers shared by tile map generation passes.
/// SPEC/program/tile-map-gen-algorithm.md

import 'tile_map_grid_graph_connectivity.dart';
import 'tile_map_grid_graph_continent.dart';
import 'tile_map_grid_graph_ocean.dart';
import 'tile_map_land_seed_contract.dart';

class TileMapGridGraph {
  TileMapGridGraph(this.params)
    : _connectivity = TileMapGridGraphConnectivity(params),
      _continent = TileMapGridGraphContinent(params);

  final TileMapLandSeedParams params;

  final TileMapGridGraphConnectivity _connectivity;
  final TileMapGridGraphContinent _continent;
  late final TileMapGridGraphOcean _ocean = TileMapGridGraphOcean(
    params,
    _connectivity,
    _continent,
  );

  List<Set<(int x, int y)>> connectedComponentsOfLand(
    Set<(int x, int y)> landCells,
  ) =>
      _connectivity.connectedComponentsOfLand(landCells);

  List<Set<(int x, int y)>> connectedComponentsOfSea(
    List<List<String>> grid,
    String seaZoneId,
  ) =>
      _connectivity.connectedComponentsOfSea(grid, seaZoneId);

  (int, int) minYx(Set<(int x, int y)> cells) => _connectivity.minYx(cells);

  int countSeaCells(List<List<String>> grid, String seaZoneId) =>
      _connectivity.countSeaCells(grid, seaZoneId);

  Set<(int x, int y)> oceanCells(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) =>
      _ocean.oceanCells(grid, seaZoneId, landSeeds, continentBySeedIndex);

  int nearestLandSeedIndexForCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
  ) =>
      _continent.nearestLandSeedIndexForCell(x, y, landSeeds);

  int continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) =>
      _continent.continentForLandCell(
        x,
        y,
        landSeeds,
        continentBySeedIndex,
      );

  int oceanNeighbourCount(
    List<List<String>> grid,
    int x,
    int y,
    String seaZoneId,
    Set<(int x, int y)> ocean,
  ) =>
      _ocean.oceanNeighbourCount(grid, x, y, seaZoneId, ocean);
}
