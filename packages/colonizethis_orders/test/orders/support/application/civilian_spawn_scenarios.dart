// Table-driven civilian / New World spawn scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'civilian_spawn_expectation_shorthand.dart';

void cspRunCivilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince() {
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    otherOwnedProvinceId: 'oldWorld|P2',
    capitalTile: const CapitalTile(
      regionId: cspOw,
      provinceId: cspCapitalProvinceId,
      x: 0,
      y: 1,
    ),
  );
  final next = applyBuildAndWorkOrders(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
          BuildUnitCategory.military,
      spawnProvinceId: 'oldWorld|P2',
    ),
  );
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.tileKey, cspCapitalTileKey);
  expect(
    next.worldState.oldWorld.units.single.locationProvinceId,
    cspCapitalProvinceId,
  );
}

void cspRunCivilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince() {
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    capitalTile: const CapitalTile(
      regionId: cspOw,
      provinceId: cspCapitalProvinceId,
      x: 0,
      y: 1,
    ),
    peasants: 0,
  );
  final next = applyBuildAndWorkOrders(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
          BuildUnitCategory.military,
      spawnProvinceId: '',
    ),
  );
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.tileKey, cspCapitalTileKey);
  expect(
    next.worldState.oldWorld.units.single.locationProvinceId,
    cspCapitalProvinceId,
  );
}

void cspRunCivilianBuildWithMissingCapitalTileThrowsExplicitError() {
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    tileKeysByProvince: {
      cspCapitalProvinceId: ['oldWorld|P1|0|0'],
    },
    peasants: 0,
  );
  final orders = cspBuildOrders(
    kUnitTypeExplorer,
    isMilitary: false,
    spawnProvinceId: cspCapitalProvinceId,
  );
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

void cspRunNewWorldSpawnAddsUnitToNewWorld() {
  const provinceId = 'newWorld|N1';
  const unitType = 'peasant_levies';
  const nw = 'newWorld';
  final econ = RegimentEconomyCatalog.byId[unitType]!;
  final baseGame = Game(
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
  final game = baseGame.copyWith(
    players: [
      baseGame.players.single.copyWith(
        stockpile: cspStockpileCovering(econ.buildInputs),
        treasury: econ.buildTreasuryCost + 10,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    cspBuildOrders(
      unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: provinceId,
    ),
  );
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.worldState.newWorld.units.length, 1);
  expect(next.worldState.newWorld.units.single.locationProvinceId, provinceId);
}

/// Canonical scenarios for civilian / New World spawn family tests.
List<RunnableScenario> civilianSpawnScenarios() => const [
  // dart format off
  rs('civilian spawn uses capitalTile key even when spawnProvinceId is different owned province', cspRunCivilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince),
  rs('civilian build with empty spawnProvinceId uses capital tile and province', cspRunCivilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince),
  rs('civilian build with missing capital tile throws explicit error', cspRunCivilianBuildWithMissingCapitalTileThrowsExplicitError),
  rs('New World spawn adds unit to newWorld', cspRunNewWorldSpawnAddsUnitToNewWorld),
  // dart format on
];
