part of 'valid_work_tiles_expectations.dart';

void _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  vwtExpectVisProspectIncludesEligibleIronTile();
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  vwtExpectVisProspectExcludesWoolOnHillsTerrain();
}

void _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {
  vwtExpectVisExplorePartialProvincesOnly();
}

void _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() {
  vwtExpectVisExploreLargeMapUnderOneSecond();
}

void _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {
  vwtExpectNoMovesToOtherGpProvince();
}

void _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {
  vwtExpectBuildSuggestionsSortedThreeTiles();
}

void _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {
  vwtExpectNoBuildForReservedTilePair();
}

void _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  vwtExpectPartialRevealExploreIncluded();
}

void _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  vwtExpectPartialRevealExploreExcluded();
}

void _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  vwtExpectPartialRevealProspectIncluded();
}
