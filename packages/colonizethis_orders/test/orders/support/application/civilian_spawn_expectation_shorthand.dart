// Compact civilian / New World spawn expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const cspOw = 'oldWorld';
const cspCapitalProvinceId = 'oldWorld|P1';
const cspCapitalTileKey = 'oldWorld|P1|0|1';

Stockpile cspStockpileCovering(Map<String, int> inputs) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value + 1);
  }
  return stockpile;
}

Game cspExplorerGame({
  required String capitalProvinceId,
  List<Province> provinces = const [],
  Map<String, List<String>>? tileKeysByProvince,
  CapitalTile? capitalTile,
  String? otherOwnedProvinceId,
  int extraTreasury = 100,
  int peasants = 1,
}) {
  final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
  final tileMap = tileKeysByProvince ??
      {
        capitalProvinceId: ['oldWorld|P1|0|0', cspCapitalTileKey],
        if (otherOwnedProvinceId != null)
          otherOwnedProvinceId: ['oldWorld|P2|0|0'],
      };
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: provinces.isNotEmpty
            ? provinces
            : [
                Province(id: capitalProvinceId, regionId: cspOw, ownerId: 'p1'),
                if (otherOwnedProvinceId != null)
                  Province(
                    id: otherOwnedProvinceId,
                    regionId: cspOw,
                    ownerId: 'p1',
                  ),
              ],
        units: [],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {cspOw: tileMap},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        capitalTile: capitalTile,
        stockpile: cspStockpileCovering(explorerEcon.buildInputs),
        workerPool: WorkerPool(peasants: peasants),
        treasury: explorerEcon.buildTreasuryCost + extraTreasury,
      ),
    ],
  );
}

Orders cspBuildOrders(
  String unitType, {
  required bool isMilitary,
  required String spawnProvinceId,
}) =>
    Orders(
      buildUnitOrdersByPlayerId: {
        'p1': [
          BuildUnitOrder(
            unitType: unitType,
            isMilitary: isMilitary,
            spawnProvinceId: spawnProvinceId,
          ),
        ],
      },
    );

Game cspApply(Game game, Orders orders) =>
    applyBuildAndWorkOrders(game, orders);

void cspExpectOwUnitAt({
  required Game next,
  required String tileKey,
  required String provinceId,
  int count = 1,
}) {
  expect(next.worldState.oldWorld.units.length, count);
  expect(next.worldState.oldWorld.units.single.tileKey, tileKey);
  expect(
    next.worldState.oldWorld.units.single.locationProvinceId,
    provinceId,
  );
}

void cspExpectMissingCapitalTileError(Game game, Orders orders) {
  expect(
    () => applyBuildAndWorkOrders(game, orders),
    throwsA(
      isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('No capital tile to spawn civilian unit'),
      ),
    ),
  );
}

void cspExpectExplorerSpawnAtCapital({
  String? spawnProvinceId,
  String? otherOwnedProvinceId,
  int peasants = 1,
}) {
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    otherOwnedProvinceId: otherOwnedProvinceId,
    capitalTile: const CapitalTile(
      regionId: cspOw,
      provinceId: cspCapitalProvinceId,
      x: 0,
      y: 1,
    ),
    peasants: peasants,
  );
  final next = cspApply(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
          BuildUnitCategory.military,
      spawnProvinceId: spawnProvinceId ?? otherOwnedProvinceId ?? '',
    ),
  );
  cspExpectOwUnitAt(
    next: next,
    tileKey: cspCapitalTileKey,
    provinceId: cspCapitalProvinceId,
  );
}

void cspExpectNewWorldMilitarySpawn({
  required String provinceId,
  required String unitType,
}) {
  final next = cspApply(
    cspNewWorldMilitaryGame(provinceId: provinceId, unitType: unitType),
    cspBuildOrders(
      unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: provinceId,
    ),
  );
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.worldState.newWorld.units.length, 1);
  expect(
    next.worldState.newWorld.units.single.locationProvinceId,
    provinceId,
  );
}

void cspExpectMissingCapitalTileBuildError() {
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    tileKeysByProvince: {
      cspCapitalProvinceId: ['oldWorld|P1|0|0'],
    },
    peasants: 0,
  );
  cspExpectMissingCapitalTileError(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary: false,
      spawnProvinceId: cspCapitalProvinceId,
    ),
  );
}

Game cspNewWorldMilitaryGame({
  required String provinceId,
  required String unitType,
}) {
  const nw = 'newWorld';
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: nw, ownerId: 'p1')],
        units: [],
      ),
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: const Stockpile(),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 500,
      ),
    ],
  );
  final econ = RegimentEconomyCatalog.byId[unitType]!;
  return game.copyWith(
    players: [
      game.players.single.copyWith(
        stockpile: cspStockpileCovering(econ.buildInputs),
        treasury: econ.buildTreasuryCost + 10,
      ),
    ],
  );
}
