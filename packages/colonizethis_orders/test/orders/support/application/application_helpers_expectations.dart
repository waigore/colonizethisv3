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
      ahExpectParseValidTileKeyDefault();
    case ApplicationHelpersTarget.returnsNullForMalformedTileKey:
      ahExpectParseMalformedTileKeysDefault();
    case ApplicationHelpersTarget.clearsWorkStateAndRestoresOriginTileByDefault:
      ahExpectCancelWorkDefault();
    case ApplicationHelpersTarget.usesExplicitRestoredTileOverride:
      ahExpectCancelWorkRestoredTileOverride();
    case ApplicationHelpersTarget.returnsGameUnchangedWhenUnitHasNoCurrentWork:
      ahExpectClearWorkUnchangedIdleBuilder();
    case ApplicationHelpersTarget
        .clearsCurrentWorkRestoresOriginTileAndSetsStatusIdle:
      ahExpectClearWorkBuilderImprovementIdleAtOrigin();
    case ApplicationHelpersTarget
        .returnsTrueForProspectableTerrainEvenWhenNoResourceIsPresent:
      ahExpectMountainProspectableWithoutResource();
    case ApplicationHelpersTarget
        .returnsFalseForNonProspectableTerrainEvenWhenMineralResourceExists:
      ahExpectPlainsGoldNotProspectable();
    case ApplicationHelpersTarget
        .returnsFalseForWoolOnHillsWhenTileMapShowsProspectableTerrain:
      ahExpectHillsWoolNotProspectable();
    case ApplicationHelpersTarget
        .returnsTrueForIronOnHillsWithTileMapWhenNotProspected:
      ahExpectHillsIronProspectable();
    case ApplicationHelpersTarget.returnsFalseWhenResourceIsAbsent:
      ahExpectAbsentResourceNotMineral();
    case ApplicationHelpersTarget.returnsFalseForNonMineralResource:
      ahExpectGrainNotMineral();
    case ApplicationHelpersTarget.returnsTrueForMineralResource:
      ahExpectCoalMineral();
  }
}
