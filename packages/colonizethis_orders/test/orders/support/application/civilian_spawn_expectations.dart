// Compact applyBuildAndWorkOrders civilian/New World spawn assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [civilianSpawnScenarios] rows.
enum CivilianSpawnTarget {
  civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince,
  civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince,
  civilianBuildWithMissingCapitalTileThrowsExplicitError,
  newWorldSpawnAddsUnitToNewWorld,
}

void runCivilianSpawnExpectation(CivilianSpawnTarget target) {
  switch (target) {
    case CivilianSpawnTarget
        .civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince:
      _civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince();
    case CivilianSpawnTarget
        .civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince:
      _civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince();
    case CivilianSpawnTarget
        .civilianBuildWithMissingCapitalTileThrowsExplicitError:
      _civilianBuildWithMissingCapitalTileThrowsExplicitError();
    case CivilianSpawnTarget.newWorldSpawnAddsUnitToNewWorld:
      _newWorldSpawnAddsUnitToNewWorld();
  }
}

Stockpile _stockpileCovering(Map<String, int> inputs) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value + 1);
  }
  return stockpile;
}

void _civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince() {
  const ow = 'oldWorld';
  const capitalProvinceId = 'oldWorld|P1';
  const otherOwnedProvinceId = 'oldWorld|P2';
  const capitalTileKey = 'oldWorld|P1|0|1';
  final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
          Province(id: otherOwnedProvinceId, regionId: ow, ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          capitalProvinceId: ['oldWorld|P1|0|0', capitalTileKey],
          otherOwnedProvinceId: ['oldWorld|P2|0|0'],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: capitalProvinceId,
          x: 0,
          y: 1,
        ),
        stockpile: _stockpileCovering(explorerEcon.buildInputs),
        workerPool: const WorkerPool(peasants: 1),
        treasury: explorerEcon.buildTreasuryCost + 100,
      ),
    ],
  );
  final orders = Orders(
    buildUnitOrdersByPlayerId: {
      'p1': [
        BuildUnitOrder(
          unitType: kUnitTypeExplorer,
          isMilitary:
              buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
              BuildUnitCategory.military,
          spawnProvinceId: otherOwnedProvinceId,
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.oldWorld.units.length, 1);
  expect(next.worldState.oldWorld.units.single.tileKey, capitalTileKey);
  expect(
    next.worldState.oldWorld.units.single.locationProvinceId,
    capitalProvinceId,
  );
}

void _civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince() {
  const ow = 'oldWorld';
  const capitalProvinceId = 'oldWorld|P1';
  const capitalTileKey = 'oldWorld|P1|0|1';
  final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          capitalProvinceId: ['oldWorld|P1|0|0', capitalTileKey],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        capitalTile: const CapitalTile(
          regionId: ow,
          provinceId: capitalProvinceId,
          x: 0,
          y: 1,
        ),
        stockpile: _stockpileCovering(explorerEcon.buildInputs),
        treasury: explorerEcon.buildTreasuryCost + 100,
      ),
    ],
  );
  final orders = Orders(
    buildUnitOrdersByPlayerId: {
      'p1': [
        BuildUnitOrder(
          unitType: kUnitTypeExplorer,
          isMilitary: false,
          spawnProvinceId: '',
        ),
      ],
    },
  );
  final next = applyBuildAndWorkOrders(game, orders);
  expect(next.worldState.oldWorld.units.length, 1);
  expect(
    next.worldState.oldWorld.units.single.locationProvinceId,
    capitalProvinceId,
  );
  expect(next.worldState.oldWorld.units.single.tileKey, capitalTileKey);
}

void _civilianBuildWithMissingCapitalTileThrowsExplicitError() {
  const ow = 'oldWorld';
  const capitalProvinceId = 'oldWorld|P1';
  final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
        ],
        units: [],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          capitalProvinceId: ['oldWorld|P1|0|0'],
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        stockpile: _stockpileCovering(explorerEcon.buildInputs),
        treasury: explorerEcon.buildTreasuryCost + 100,
      ),
    ],
  );
  final orders = Orders(
    buildUnitOrdersByPlayerId: {
      'p1': [
        BuildUnitOrder(
          unitType: kUnitTypeExplorer,
          isMilitary: false,
          spawnProvinceId: capitalProvinceId,
        ),
      ],
    },
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

void _newWorldSpawnAddsUnitToNewWorld() {
  const nw = 'newWorld';
  const provinceId = 'newWorld|N1';
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
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: Stockpile(),
        workerPool: WorkerPool(peasants: 1),
        treasury: 500,
      ),
    ],
  );
  final orders = Orders(
    buildUnitOrdersByPlayerId: {
      'p1': [
        BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary:
              buildUnitCategoryForUnitType('peasant_levies') ==
              BuildUnitCategory.military,
          spawnProvinceId: provinceId,
        ),
      ],
    },
  );
  final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
  final gameWithStock = game.copyWith(
    players: [
      game.players.single.copyWith(
        stockpile: _stockpileCovering(econ.buildInputs),
        treasury: econ.buildTreasuryCost + 10,
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(gameWithStock, orders);
  expect(next.worldState.oldWorld.units, isEmpty);
  expect(next.worldState.newWorld.units.length, 1);
  expect(
    next.worldState.newWorld.units.single.locationProvinceId,
    provinceId,
  );
}
