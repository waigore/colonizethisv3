// Compact applyBuildAndWorkOrders civilian/New World spawn assertions (Refs #3949 wave 3).

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
  cspExpectExplorerSpawnAtCapital(
    spawnProvinceId: 'oldWorld|P2',
    otherOwnedProvinceId: 'oldWorld|P2',
  );
}

void _civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince() {
  cspExpectExplorerSpawnAtCapital(peasants: 0);
}

void _civilianBuildWithMissingCapitalTileThrowsExplicitError() {
  cspExpectMissingCapitalTileBuildError();
}

void _newWorldSpawnAddsUnitToNewWorld() {
  cspExpectNewWorldMilitarySpawn(
    provinceId: 'newWorld|N1',
    unitType: 'peasant_levies',
  );
}
