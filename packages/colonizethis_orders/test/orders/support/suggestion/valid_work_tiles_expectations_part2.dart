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
  final fx = vwtTribePartialFx();
  vwtExpectSuggestExploreTargetsProvince(
    vwtTribeConsulateGame(fx, id: 'g1916e1'),
    fx.topology(),
    fx.provTarget,
  );
}

void _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  vwtExpectSuggestExploreExcludesProvince(
    fx.game(
      id: 'g1916e2',
      players: [
        ValidWorkTilesTestSupport.defaultPlayer,
        const Player(id: 'gp2', displayName: 'P2', isHuman: false),
      ],
    ),
    fx.topology(),
    fx.provTarget,
  );
}

void _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final fx = vwtTribeGrainIronFx();
  vwtExpectSuggestProspectIncludesTile(
    vwtTribeConsulateGame(fx, id: 'g1916p1'),
    fx.topology(),
    fx.t1,
  );
}
