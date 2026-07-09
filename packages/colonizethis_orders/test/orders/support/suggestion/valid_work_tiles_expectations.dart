// Compact getValidWorkOrderTileKeys / suggestWorkOrders assertions (Refs #3949 wave 3).

import 'valid_work_tiles_expectation_shorthand.dart';

/// Pins for [validWorkTilesScenarios] rows.
enum ValidWorkTilesTarget {
  returnsEmptyForUnknownUnitId,
  returnsEmptyWhenWorkTargetNotAllowedForUnitType,
  returnsEmptyForUnknownUnitIdWithVisibility,
  returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility,
  filtersByVisibilityBeforeOrderEngineValidation,
  buildImprovementReturnsOnlyControlledTilesWithResources,
  buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected,
  buildImprovementIncludesPurchasedTilesWithResources,
  buildImprovementExcludesSeaZoneTiles,
  getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected,
  getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile,
  getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility,
  getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces,
  getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture,
  suggestmoveordersExcludesMovesToOtherGreatPowerProvinces,
  suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch,
  suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit,
  suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut,
  suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation,
  suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile,
  suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral,
  suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy,
  suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail,
}

void runValidWorkTilesExpectation(ValidWorkTilesTarget target) {
  switch (target) {
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitId:
      vwtExpectUnknownUnitExploreEmpty();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType:
      vwtExpectExplorerDisallowedBuildEmpty();
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility:
      vwtExpectUnknownUnitExploreEmptyWithVisibility();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility:
      vwtExpectExplorerDisallowedBuildEmptyWithVisibility();
    case ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation:
      vwtExpectColonistVisibilityFilterMatchesPlain();
    case ValidWorkTilesTarget.buildImprovementReturnsOnlyControlledTilesWithResources:
      vwtExpectControlledTilesWithResourcesOnly();
    case ValidWorkTilesTarget
        .buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      vwtExpectOwnedMineralBuildGateDefaultTiles();
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
      vwtExpectPurchasedTileIncluded();
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
      vwtExpectSeaZoneTileExcluded();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected:
      vwtExpectVisProspectExcludesGrassAndProspectedIron();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
      vwtExpectVisProspectIncludesEligibleIronTile();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
      vwtExpectVisProspectExcludesWoolOnHillsTerrain();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces:
      vwtExpectVisExplorePartialProvincesOnly();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      vwtExpectVisExploreLargeMapUnderOneSecond();
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      vwtExpectNoMovesToOtherGpProvince();
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
      vwtExpectBuildSuggestionsSortedThreeTiles();
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      vwtExpectNoBuildForReservedTilePair();
    case ValidWorkTilesTarget
        .suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut:
      vwtExpectPartialRevealExploreIncluded();
    case ValidWorkTilesTarget
        .suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
      vwtExpectPartialRevealExploreExcluded();
    case ValidWorkTilesTarget
        .suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      vwtExpectPartialRevealProspectIncluded();
    case ValidWorkTilesTarget
        .suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      vwtExpectProspectExcludedWhenIronProspected(
        vwtTribeGrainIronFx(prospectedIron: true),
      );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      vwtExpectMinorPurchaseLandIncludedWithEmbassy();
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      vwtExpectMinorPurchaseLandExcludedWithoutEmbassy();
  }
}
