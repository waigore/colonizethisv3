// Compact orders_application_helpers + clearUnitCurrentWork assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';

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
      _returnsParsedCoordinatesForAValidTileKey();
    case ApplicationHelpersTarget.returnsNullForMalformedTileKey:
      _returnsNullForMalformedTileKey();
    case ApplicationHelpersTarget.clearsWorkStateAndRestoresOriginTileByDefault:
      _clearsWorkStateAndRestoresOriginTileByDefault();
    case ApplicationHelpersTarget.usesExplicitRestoredTileOverride:
      _usesExplicitRestoredTileOverride();
    case ApplicationHelpersTarget.returnsGameUnchangedWhenUnitHasNoCurrentWork:
      _returnsGameUnchangedWhenUnitHasNoCurrentWork();
    case ApplicationHelpersTarget
        .clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle:
      _clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle();
    case ApplicationHelpersTarget
        .returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent:
      _returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent();
    case ApplicationHelpersTarget
        .returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists:
      _returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists();
    case ApplicationHelpersTarget
        .returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain:
      _returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain();
    case ApplicationHelpersTarget
        .returnsTrueForIronOnHillsWithTileMapWhenNotProspected:
      _returnsTrueForIronOnHillsWithTileMapWhenNotProspected();
    case ApplicationHelpersTarget.returnsFalseWhenResourceIsAbsent:
      _returnsFalseWhenResourceIsAbsent();
    case ApplicationHelpersTarget.returnsFalseForNonMineralResource:
      _returnsFalseForNonMineralResource();
    case ApplicationHelpersTarget.returnsTrueForMineralResource:
      _returnsTrueForMineralResource();
  }
}

void _returnsParsedCoordinatesForAValidTileKey() {
  ahExpectParseTileKey(
    'oldWorld|P1|12|7',
    regionId: 'oldWorld',
    provinceLocalId: 'P1',
    x: 12,
    y: 7,
  );
}

void _returnsNullForMalformedTileKey() {
  ahExpectMalformedTileKeys(['oldWorld|P1|12', 'oldWorld|P1|x|7']);
}

void _clearsWorkStateAndRestoresOriginTileByDefault() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(id: 'u1'),
    expectedTile: 'oldWorld|P1|1|1',
  );
}

void _usesExplicitRestoredTileOverride() {
  ahExpectCancelWorkClearsState(
    ahWorkingUnit(
      id: 'u2',
      originTileKey: null,
      assignedTileKey: null,
    ),
    restoredTile: 'oldWorld|P1|0|0',
    expectedTile: 'oldWorld|P1|0|0',
  );
}

void _returnsGameUnchangedWhenUnitHasNoCurrentWork() {
  ahExpectClearWorkUnchanged(
    ahOwBuilderGame(ahIdleBuilderUnit()),
    'u1',
  );
}

void _clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle() {
  ahExpectClearWorkIdleAtOrigin(
    ahOwBuilderGame(ahBuilderWithImprovementWork()),
    'u1',
    'oldWorld|p1|0|0',
  );
}

void _returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: 'oldWorld|p1|0|0',
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(terrain: TerrainType.mountain),
    },
    expected: true,
  );
}

void _returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists() {
  ahExpectMineralEligible(
    resourceByTile: const {'oldWorld|p1|0|0': 'gold'},
    tileKey: 'oldWorld|p1|0|0',
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.plains,
        resource: Resource.gold,
      ),
    },
    expected: false,
  );
}

void _returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain() {
  ahExpectMineralEligible(
    resourceByTile: const {'oldWorld|p1|0|0': 'wool'},
    tileKey: 'oldWorld|p1|0|0',
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.hills,
        resource: Resource.wool,
      ),
    },
    expected: false,
  );
}

void _returnsTrueForIronOnHillsWithTileMapWhenNotProspected() {
  ahExpectMineralEligible(
    resourceByTile: const {'oldWorld|p1|0|0': 'iron'},
    tileKey: 'oldWorld|p1|0|0',
    tileMapByRegion: {
      'oldWorld': ahSingleTileMap(
        terrain: TerrainType.hills,
        resource: Resource.iron,
      ),
    },
    expected: true,
  );
}

void _returnsFalseWhenResourceIsAbsent() {
  ahExpectMineralEligible(
    resourceByTile: const {},
    tileKey: 'oldWorld|p1|0|0',
    expected: false,
  );
}

void _returnsFalseForNonMineralResource() {
  ahExpectMineralEligible(
    resourceByTile: const {'oldWorld|p1|0|0': 'grain'},
    tileKey: 'oldWorld|p1|0|0',
    expected: false,
  );
}

void _returnsTrueForMineralResource() {
  ahExpectMineralEligible(
    resourceByTile: const {'oldWorld|p1|0|0': 'coal'},
    tileKey: 'oldWorld|p1|0|0',
    expected: true,
  );
}
