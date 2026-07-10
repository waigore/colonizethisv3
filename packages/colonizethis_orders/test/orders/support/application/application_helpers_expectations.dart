// Compact orders_application_helpers + clearUnitCurrentWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'application_helpers_expectation_shorthand.dart';

/// Pins for [applicationHelpersScenarios] rows.
enum ApplicationHelpersTarget {
  returnsParsedCoordinatesForAValidTileKey,
  returnsNullForMalformedTileKey,
  clearsWorkStateAndRestoresOriginTileByDefault,
  usesExplicitRestoredTileOverride,
  returnsGameUnchangedWhenUnitHasNoCurrentWork,
  clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle,
  returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent,
  returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists,
  returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain,
  returnsTrueForIronOnHillsWithTileMapWhenNotProspected,
  returnsFalseWhenResourceIsAbsent,
  returnsFalseForNonMineralResource,
  returnsTrueForMineralResource,
}

void runApplicationHelpersExpectation(ApplicationHelpersTarget target) {
  switch (target) {
    case ApplicationHelpersTarget.returnsParsedCoordinatesForAValidTileKey:
      {
        const tileKey = 'oldWorld|P1|12|7';
        final parsed = parseTileKeyCoordinates(tileKey);
        expect(parsed, isNotNull);
        expect(parsed!.regionId, 'oldWorld');
        expect(parsed.provinceLocalId, 'P1');
        expect(parsed.x, 12);
        expect(parsed.y, 7);
      }
    case ApplicationHelpersTarget.returnsNullForMalformedTileKey:
      for (final key in ['oldWorld|P1|12', 'oldWorld|P1|x|7']) {
        expect(parseTileKeyCoordinates(key), isNull);
      }
    case ApplicationHelpersTarget.clearsWorkStateAndRestoresOriginTileByDefault:
        ahExpectCancelWorkClearsState(
          ahWorkingUnit(id: 'u1'),
          expectedTile: 'oldWorld|P1|1|1',
        );
    case ApplicationHelpersTarget.usesExplicitRestoredTileOverride:
        ahExpectCancelWorkClearsState(
          ahWorkingUnit(
            id: 'u2',
            originTileKey: null,
            assignedTileKey: null,
          ),
          restoredTile: 'oldWorld|P1|0|0',
          expectedTile: 'oldWorld|P1|0|0',
        );
    case ApplicationHelpersTarget.returnsGameUnchangedWhenUnitHasNoCurrentWork:
      {
        final game = ahOwBuilderGame(
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
          ),
        );
        final result = clearUnitCurrentWork(game, 'u1');
        expect(identical(result, game), isTrue);
      }
    case ApplicationHelpersTarget
        .clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle:
      {
        const originTile = 'oldWorld|p1|0|0';
        final game = ahOwBuilderGame(
          Unit(
            id: 'u1',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            tileKey: originTile,
            originTileKey: originTile,
            assignedTileKey: 'oldWorld|p1|1|0',
            status: UnitStatus.working,
            currentWork: CurrentWork(
              workTarget: kWorkTargetBuildImprovement,
              tileKey: 'oldWorld|p1|1|0',
              totalTurns: 2,
              remainingTurns: 1,
            ),
          ),
        );
        final result = clearUnitCurrentWork(game, 'u1');
        final unit = result.worldState.oldWorld.units.single;
        expect(unit.currentWork, isNull);
        expect(unit.status, UnitStatus.idle);
        expect(unit.tileKey, originTile);
        expect(unit.originTileKey, isNull);
        expect(unit.assignedTileKey, isNull);
      }
    case ApplicationHelpersTarget
        .returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent:
        ahExpectMineralEligible(
          resourceByTile: const {},
          tileKey: ahMineralTileKey,
          tileMapByRegion: {
            'oldWorld': ahSingleTileMap(terrain: TerrainType.mountain),
          },
          expected: true,
        );
    case ApplicationHelpersTarget
        .returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists:
        ahExpectMineralEligible(
          resourceByTile: const {ahMineralTileKey: 'gold'},
          tileKey: ahMineralTileKey,
          tileMapByRegion: {
            'oldWorld': ahSingleTileMap(
              terrain: TerrainType.plains,
              resource: Resource.gold,
            ),
          },
          expected: false,
        );
    case ApplicationHelpersTarget
        .returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain:
        ahExpectMineralEligible(
          resourceByTile: const {ahMineralTileKey: 'wool'},
          tileKey: ahMineralTileKey,
          tileMapByRegion: {
            'oldWorld': ahSingleTileMap(
              terrain: TerrainType.hills,
              resource: Resource.wool,
            ),
          },
          expected: false,
        );
    case ApplicationHelpersTarget
        .returnsTrueForIronOnHillsWithTileMapWhenNotProspected:
        ahExpectMineralEligible(
          resourceByTile: const {ahMineralTileKey: 'iron'},
          tileKey: ahMineralTileKey,
          tileMapByRegion: {
            'oldWorld': ahSingleTileMap(
              terrain: TerrainType.hills,
              resource: Resource.iron,
            ),
          },
          expected: true,
        );
    case ApplicationHelpersTarget.returnsFalseWhenResourceIsAbsent:
        ahExpectMineralEligible(
          resourceByTile: const {},
          tileKey: ahMineralTileKey,
          expected: false,
        );
    case ApplicationHelpersTarget.returnsFalseForNonMineralResource:
        ahExpectMineralEligible(
          resourceByTile: const {ahMineralTileKey: 'grain'},
          tileKey: ahMineralTileKey,
          expected: false,
        );
    case ApplicationHelpersTarget.returnsTrueForMineralResource:
        ahExpectMineralEligible(
          resourceByTile: const {ahMineralTileKey: 'coal'},
          tileKey: ahMineralTileKey,
          expected: true,
        );
  }
}
