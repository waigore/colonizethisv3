// Compact applyBuildAndWorkOrders civilian/New World spawn assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'civilian_spawn_expectation_shorthand.dart';

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

void
_civilianSpawnUsesCapitalTileKeyEvenWhenSpawnProvinceIdIsDifferentOwnedProvince() {
  const otherOwned = 'oldWorld|P2';
  final game = cspExplorerGame(
    capitalProvinceId: cspCapitalProvinceId,
    otherOwnedProvinceId: otherOwned,
    capitalTile: const CapitalTile(
      regionId: cspOw,
      provinceId: cspCapitalProvinceId,
      x: 0,
      y: 1,
    ),
  );
  final next = cspApply(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
          BuildUnitCategory.military,
      spawnProvinceId: otherOwned,
    ),
  );
  cspExpectOwUnitAt(
    next: next,
    tileKey: cspCapitalTileKey,
    provinceId: cspCapitalProvinceId,
  );
}

void _civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince() {
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
  final next = cspApply(
    game,
    cspBuildOrders(
      kUnitTypeExplorer,
      isMilitary: false,
      spawnProvinceId: '',
    ),
  );
  cspExpectOwUnitAt(
    next: next,
    tileKey: cspCapitalTileKey,
    provinceId: cspCapitalProvinceId,
  );
}

void _civilianBuildWithMissingCapitalTileThrowsExplicitError() {
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

void _newWorldSpawnAddsUnitToNewWorld() {
  const provinceId = 'newWorld|N1';
  const unitType = 'peasant_levies';
  final gameWithStock = cspNewWorldMilitaryGame(
    provinceId: provinceId,
    unitType: unitType,
  );
  final next = cspApply(
    gameWithStock,
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
