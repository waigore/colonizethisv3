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
      cspExpectExplorerSpawnAtCapital(
        spawnProvinceId: 'oldWorld|P2',
        otherOwnedProvinceId: 'oldWorld|P2',
      );
    case CivilianSpawnTarget
        .civilianBuildWithEmptySpawnProvinceIdUsesCapitalTileAndProvince:
      cspExpectExplorerSpawnAtCapital(peasants: 0);
    case CivilianSpawnTarget
        .civilianBuildWithMissingCapitalTileThrowsExplicitError:
      {
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
    case CivilianSpawnTarget.newWorldSpawnAddsUnitToNewWorld:
      {
        const provinceId = 'newWorld|N1';
        const unitType = 'peasant_levies';
        final next = cspApply(
          cspNewWorldMilitaryGame(provinceId: provinceId, unitType: unitType),
          cspBuildOrders(
            unitType,
            isMilitary:
                buildUnitCategoryForUnitType(unitType) ==
                BuildUnitCategory.military,
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
  }
}
