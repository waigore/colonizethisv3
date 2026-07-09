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
      cspExpectExplorerSpawnAtCapital(
        spawnProvinceId: 'oldWorld|P2',
        otherOwnedProvinceId: 'oldWorld|P2',
      );
    case CivilianSpawnTarget
        .civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince:
      cspExpectExplorerSpawnAtCapital(peasants: 0);
    case CivilianSpawnTarget
        .civilianBuildWithMissingCapitalTileThrowsExplicitError:
      cspExpectMissingCapitalTileBuildError();
    case CivilianSpawnTarget.newWorldSpawnAddsUnitToNewWorld:
      cspExpectNewWorldMilitarySpawn(
        provinceId: 'newWorld|N1',
        unitType: 'peasant_levies',
      );
  }
}
