// Owned-tile graph + province tile lookup (Refs #4258 Slices C/D).
// dart format off
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/owned_tile_graph.dart';
import 'package:colonizethis_orders/src/orders/province_tile_lookup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_core_fixtures.dart';

TileMapResult _row3() => TileMapResult(width: 3, height: 1, grid: const [['p1', 'p1', 'p1']], terrainGrid: const [[TerrainType.plains, TerrainType.plains, TerrainType.plains]]);

void otgRunRoadFirstPathMatchesExtensionDistance() {
  final t0 = OscIds.tile('p1', 0, 0);
  final t1 = OscIds.tile('p1', 1, 0);
  final t2 = OscIds.tile('p1', 2, 0);
  final g = oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId)]), tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [t0, t1, t2]})));
  final topology = oscProvinceTopology(['p1']);
  final maps = {'oldWorld': _row3()};
  final path = shortestOwnedTilePathToConnectedNetwork(game: g, playerId: OscIds.playerId, startTileKey: t2, connectedTileKeys: {t0}, tileMapByRegion: maps, topology: topology);
  expect(path, [t2, t1, t0]);
  final ownedLand = ownedLandTileKeysForPlayer(game: g, playerId: OscIds.playerId);
  final distances = extensionDistancesOverOwnedLand(
    startTargets: {t2},
    ownedLandTiles: ownedLand,
    tileMapByRegion: maps,
    landProvinceIds: provinceNodeIds(topology),
  );
  expect(distances[t2], 0);
  expect(distances[t1], 1);
  expect(distances[t0], 2);
}

void ptlRunResolvesPrefixedTileKeyByRegion() {
  const tileKey = 'oldWorld|p1|0|0';
  final world = oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId)]));
  final province = tryGetProvinceAtTileKey(world, tileKey);
  expect(province, isNotNull);
  expect(province!.id, OscIds.prov('p1'));
  expect(province.ownerId, OscIds.playerId);
}

void ptlRunReturnsNullForMalformedTileKey() {
  final world = oscWorld();
  expect(tryGetProvinceAtTileKey(world, 'p1|0|0'), isNull);
}

void main() {
  runLabeledScenarioGroup('ownedTileGraph', [
    rs('road-first path and connectivity extension distances agree on owned land', otgRunRoadFirstPathMatchesExtensionDistance, '#4258'),
  ], runRunnableScenario);
  runLabeledScenarioGroup('provinceTileLookup', [
    rs('tryGetProvinceAtTileKey resolves prefixed tile keys by region', ptlRunResolvesPrefixedTileKeyByRegion, '#4258'),
    rs('tryGetProvinceAtTileKey returns null for unprefixed tile keys', ptlRunReturnsNullForMalformedTileKey, '#4258'),
  ], runRunnableScenario);
}
