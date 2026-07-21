// dart format off
// Tile-map and connectivity helpers for extraction fixtures (Refs #3661, #4108 slice B).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
TileMapResult singleTileMap(Resource? resource, {String province = 'p1'}) => TileMapResult(
  width: 1,
  height: 1,
  grid: [
    [province],
  ],
  resourceGrid: [
    [resource],
  ],
);
Map<String, TileMapResult> tileMapByRegionForResource(Resource resource, {String regionId = 'oldWorld', String province = 'M1'}) => {regionId: singleTileMap(resource, province: province)};
class TileImprovementSpec {
  const TileImprovementSpec(this.tileKey, [this.improvement = 0, this.roadLevel = 0]);
  final String tileKey;
  final int improvement;
  final int roadLevel;
}
List<TileImprovementSpec> tileImps(Iterable<String> tileKeys, [int improvement = 1, int roadLevel = 1]) => [for (final key in tileKeys) TileImprovementSpec(key, improvement, roadLevel)];
TileMapState tileStateFromSpecs(Iterable<TileImprovementSpec> specs) {
  var state = TileMapState();
  for (final TileImprovementSpec spec in specs) {
    if (spec.improvement > 0) {
      state = state.setImprovement(spec.tileKey, spec.improvement);
    }
    if (spec.roadLevel > 0) {
      state = state.setRoadLevel(spec.tileKey, spec.roadLevel);
    }
  }
  return state;
}
TileMapResult nonGpProvMap(String provinceId, List<List<Resource?>> resources) {
  final height = resources.length;
  final width = resources.first.length;
  final localId = provinceId.split('|').last;
  final grid = List<List<String>>.generate(height, (_) => List<String>.filled(width, localId));
  return tileMapFromGrids(grid: grid, resourceGrid: resources);
}
TileMapResult tileMapFromGrids({required List<List<String>> grid, required List<List<Resource?>> resourceGrid}) => TileMapResult(width: grid.first.length, height: grid.length, grid: grid, resourceGrid: resourceGrid);
Map<String, ConnectivityResult> connectivityFor(Set<String> connected, {Map<String, int> pathTransportCap = const {}, Set<String> connectedByRoadRule = const {}, String playerId = 'pl1'}) => {playerId: ConnectivityResult(connected: connected, pathTransportCap: pathTransportCap, connectedByRoadRule: connectedByRoadRule)};
Map<String, ConnectivityResult> connectivityByFaction(Map<String, Set<String>> byFaction) => {for (final e in byFaction.entries) e.key: ConnectivityResult(connected: e.value)};
const String kOwP1Tile00 = 'oldWorld|p1|0|0';
TileImprovementSpec owP1Imp([int improvement = 0, int roadLevel = 0]) => TileImprovementSpec(kOwP1Tile00, improvement, roadLevel);
// dart format on
