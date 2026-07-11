// Compact OrderEngine move/work-context expectation shorthands
// (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../common/game_graphs.dart';
import 'order_engine_move_and_work_context_fixtures.dart';

const oemwcTileP1 = 'oldWorld|P1|0|0';

// dart format off
Game oemwcExplorerProvinceGame({
  required String tileVisibility,
  String provinceOwnerId = 'p1',
  String? resourceByTileKey,
  Set<String>? prospectedTiles,
  List<OvertureState>? overtureStates,
  String tileKey = oemwcTileP1,
}) => ordersOwRegionGame(
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  oldWorld: RegionData(
    provinces: [Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: provinceOwnerId)],
    units: [Unit(id: 'u1', type: kUnitTypeExplorer, ownerId: 'p1', locationProvinceId: '$oemwcOw|P1', tileKey: tileKey)],
  ),
  resourceByTileKey: resourceByTileKey == null ? const {} : {tileKey: resourceByTileKey},
  playerProspectedTiles: prospectedTiles == null ? const {} : {'p1': prospectedTiles},
  playerVisibilityByTile: {'p1': {tileKey: tileVisibility}},
  tribes: provinceOwnerId == 'tribe1' ? const [Tribe(id: 'tribe1', displayName: 'Tribe 1')] : const [],
  overtureStates: overtureStates ?? const [],
);

Game oemwcThreeProvinceUnitGame({required String unitType, required String p3OwnerId}) => ordersOwRegionGame(
  players: p3OwnerId == 'p2'
      ? const [Player(id: 'p1', displayName: 'P1', isHuman: true), Player(id: 'p2', displayName: 'P2', isHuman: true)]
      : const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  oldWorld: RegionData(
    provinces: [
      Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
      Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
      Province(id: '$oemwcOw|P3', regionId: oemwcOw, ownerId: p3OwnerId),
    ],
    units: [Unit(id: 'u1', type: unitType, ownerId: 'p1', locationProvinceId: '$oemwcOw|P1')],
  ),
  playerVisibilityByTile: oemwcThreeTilesVisible,
);

void oemwcExpectWork(
  Game game,
  MapTopology topology,
  WorkOrder order, {
  required OrderValidationStatus status,
  String? reasonContains,
  String playerId = 'p1',
}) {
  final engine = OrderEngine()..addWorkOrder(playerId, order);
  final results = engine.validatePlayerOrdersWithContext(game, topology, playerId);
  expect(results.length, 1);
  expect(results[0].status, status);
  if (reasonContains != null) expect(results[0].reason, contains(reasonContains));
}

void oemwcExpectMove(
  Game game,
  MapTopology topology,
  MoveOrder order, {
  required OrderValidationStatus status,
  String? reasonContains,
  String playerId = 'p1',
}) {
  final engine = OrderEngine()..addMoveOrder(playerId, order);
  final results = engine.validatePlayerOrdersWithContext(game, topology, playerId);
  expect(results.single.status, status);
  if (reasonContains != null) expect(results.single.reason, contains(reasonContains));
}
// dart format on
