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
        ahExpectParseTileKey(
          'oldWorld|P1|12|7',
          regionId: 'oldWorld',
          provinceLocalId: 'P1',
          x: 12,
          y: 7,
        );
    case ApplicationHelpersTarget.returnsNullForMalformedTileKey:
        ahExpectMalformedTileKeys(['oldWorld|P1|12', 'oldWorld|P1|x|7']);
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
        ahExpectClearWorkUnchanged(
          ahOwBuilderGame(ahIdleBuilderUnit()),
          'u1',
        );
    case ApplicationHelpersTarget
        .clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle:
        ahExpectClearWorkIdleAtOrigin(
          ahOwBuilderGame(ahBuilderWithImprovementWork()),
          'u1',
          'oldWorld|p1|0|0',
        );
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
