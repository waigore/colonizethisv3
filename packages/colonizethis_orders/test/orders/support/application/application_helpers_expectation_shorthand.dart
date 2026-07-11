// Compact application-helpers expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../common/game_graphs.dart';

TileMapResult ahSingleTileMap({
  required TerrainType terrain,
  Resource? resource,
}) {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['p1'],
    ],
    terrainGrid: [
      [terrain],
    ],
    resourceGrid: [
      [resource],
    ],
  );
}

Unit ahWorkingUnit({
  required String id,
  String type = 'worker',
  String ownerId = 'p1',
  String locationProvinceId = 'oldWorld|P1',
  String tileKey = 'oldWorld|P1|2|2',
  String? originTileKey = 'oldWorld|P1|1|1',
  String? assignedTileKey = 'oldWorld|P1|3|3',
  String workTarget = kWorkTargetBuildRoad,
  String workTileKey = 'oldWorld|P1|3|3',
  int remainingTurns = 2,
  int totalTurns = 3,
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
    originTileKey: originTileKey,
    assignedTileKey: assignedTileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: workTarget,
      tileKey: workTileKey,
      remainingTurns: remainingTurns,
      totalTurns: totalTurns,
    ),
  );
}

void ahExpectCancelWorkClearsState(
  Unit unit, {
  String? restoredTile,
  required String expectedTile,
}) {
  final cancelled = cancelUnitWork(unit, restoredTile: restoredTile);
  expect(cancelled.status, UnitStatus.idle);
  expect(cancelled.tileKey, expectedTile);
  expect(cancelled.currentWork, isNull);
  if (restoredTile == null) {
    expect(cancelled.originTileKey, isNull);
    expect(cancelled.assignedTileKey, isNull);
  }
}

Game ahOwBuilderGame(
  Unit unit, {
  String playerId = 'gp1',
  String ow = 'oldWorld',
  String provinceLocalId = 'p1',
}) => ordersOwRegionGame(
  id: 'g1',
  turnNumber: 1,
  players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
  oldWorld: RegionData(
    provinces: [
      Province(id: '$ow|$provinceLocalId', regionId: ow, ownerId: playerId),
    ],
    units: [unit],
  ),
);

void ahExpectMineralEligible({
  required Map<String, String> resourceByTile,
  required String tileKey,
  Map<String, TileMapResult>? tileMapByRegion,
  required bool expected,
}) {
  expect(
    isMineralEligibleTile(
      Game(
        id: 'g-test',
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        minorNations: const [],
        tribes: const [],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          resourceByTileKey: resourceByTile,
        ),
      ),
      tileMapByRegion,
      tileKey,
    ),
    expected,
  );
}

const ahMineralTileKey = 'oldWorld|p1|0|0';
