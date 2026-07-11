// Shared fixtures for build-unit / training scenarios (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

/// Canonical ids for build-unit / training expectation bodies.
abstract final class ButIds {
  static const playerId = 'p1';
  static const ow = 'oldWorld';

  static String prov(String local) => '$ow|$local';
}

// dart format off
Game butOwGame({
  required List<Player> players,
  List<Province>? provinces,
  List<Fleet>? fleets,
  String provinceId = 'oldWorld|P1',
}) => ordersOwRegionGame(
  id: 'g',
  players: players,
  oldWorld: RegionData(
    provinces: provinces ?? [Province(id: provinceId, regionId: ButIds.ow, ownerId: ButIds.playerId)],
    units: const [],
  ),
  fleets: fleets ?? const [],
);

Player _butPlayer({
  required int treasury,
  Stockpile stockpile = const Stockpile(),
  WorkerPool workerPool = const WorkerPool(peasants: 0),
  Map<String, bool>? techUnlocked,
  String? capitalProvinceId,
  CapitalTile? capitalTile,
  String displayName = 'Player 1',
}) => Player(id: ButIds.playerId, displayName: displayName, isHuman: true, capitalProvinceId: capitalProvinceId, capitalTile: capitalTile, stockpile: stockpile, workerPool: workerPool, treasury: treasury, techUnlocked: techUnlocked);

Game butMilitaryBaseGame({required int peasants, required int treasury}) =>
    butOwGame(players: [_butPlayer(treasury: treasury, workerPool: WorkerPool(peasants: peasants))]);

Orders butOrdersFor(String unitType, {String? spawnProvinceId}) {
  final spawn = spawnProvinceId ?? ButIds.prov('P1');
  return Orders(buildUnitOrdersByPlayerId: {ButIds.playerId: [BuildUnitOrder(unitType: unitType, isMilitary: buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military, spawnProvinceId: spawn)]});
}

Game butCivilianGame({required int treasury, required int paper, Map<String, bool>? techUnlocked}) {
  var stockpile = const Stockpile();
  if (paper > 0) stockpile = stockpile.applyDelta(CommodityCatalog.paper.id, paper);
  return butOwGame(players: [_butPlayer(treasury: treasury, stockpile: stockpile, capitalProvinceId: ButIds.prov('P1'), capitalTile: const CapitalTile(regionId: ButIds.ow, provinceId: 'P1', x: 0, y: 0), techUnlocked: techUnlocked)]);
}

Stockpile butStockpileCovering(Map<String, int> inputs, {int surplus = 1}) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {stockpile = stockpile.applyDelta(e.key, e.value + surplus);}
  return stockpile;
}

MapTopology _butSeaTopology({required bool adjacent}) => MapTopology(
  nodes: const [TopologyNode(id: 'P1', regionId: ButIds.ow, type: TopologyNodeType.province), TopologyNode(id: 'sea1', regionId: ButIds.ow, type: TopologyNodeType.seaZone)],
  edges: adjacent ? const [TopologyEdge(id1: 'P1', id2: 'sea1')] : const [],
);

MapTopology butCapitalAdjacentSeaTopology() => _butSeaTopology(adjacent: true);
MapTopology butCapitalIsolatedSeaTopology() => _butSeaTopology(adjacent: false);

Game butRegimentBuildGame({required Map<String, int> buildInputs, required int peasants, required int treasury, Map<String, bool>? techUnlocked}) =>
    butOwGame(players: [_butPlayer(treasury: treasury, stockpile: butStockpileCovering(buildInputs), workerPool: WorkerPool(peasants: peasants), techUnlocked: techUnlocked, displayName: 'P1')]);

Player butShipBuildPlayer({required Stockpile stockpile, required int peasants, required int treasury, Map<String, bool>? techUnlocked, String? capitalProvinceId, String displayName = 'P1'}) =>
    _butPlayer(treasury: treasury, stockpile: stockpile, workerPool: WorkerPool(peasants: peasants), techUnlocked: techUnlocked, capitalProvinceId: capitalProvinceId, displayName: displayName);

Game butShipBuildGame({required Player player, String provinceId = 'oldWorld|P1'}) => butOwGame(players: [player], provinceId: provinceId);

Stockpile butDoubleShipBuildStockpile(Map<String, int> buildInputs) {
  var stockpile = const Stockpile();
  for (final e in buildInputs.entries) {stockpile = stockpile.applyDelta(e.key, e.value * 2 + 1);}
  return stockpile;
}

Game butSecondNavalBuildGame({required Player player, required List<Fleet> fleets}) =>
    butOwGame(players: [player], provinceId: ButIds.prov('P1'), fleets: fleets);
// dart format on
