// Compact orders_application_helpers + clearUnitCurrentWork assertions (Refs #3949 wave 3).

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
  ahExpectMountainProspectableWithoutResource();
}

void _returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists() {
  ahExpectPlainsGoldNotProspectable();
}

void _returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain() {
  ahExpectHillsWoolNotProspectable();
}

void _returnsTrueForIronOnHillsWithTileMapWhenNotProspected() {
  ahExpectHillsIronProspectable();
}

void _returnsFalseWhenResourceIsAbsent() {
  ahExpectAbsentResourceNotMineral();
}

void _returnsFalseForNonMineralResource() {
  ahExpectGrainNotMineral();
}

void _returnsTrueForMineralResource() {
  ahExpectCoalMineral();
}
