part of 'valid_work_tiles_expectations.dart';

void _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectVisProspectContains(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [ironTile],
      resourceByTileKey: {ironTile: 'iron'},
      visibilityByTile: {ironTile: 'fogged'},
    ),
    owSingleProvinceTopology('p1'),
    ironTile,
  );
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectVisProspectExcludes(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [woolTile],
      resourceByTileKey: {woolTile: 'wool'},
      visibilityByTile: {woolTile: 'fogged'},
    ),
    owSingleProvinceTopology('p1'),
    woolTile,
    tileMapByRegion: vwtHillsWoolTileMap('p1'),
  );
}

void _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {
  final fx = owTribeExploreMultiProvinceFixture();
  vwtExpectVisExplore(
    game: fx.game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    includedTiles: [fx.partialKnownTile],
    excludedTiles: [fx.fullTile, fx.unknownTile],
  );
}

void _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() {
  vwtExpectVisExploreLatencyUnder(
    game: owTribeExploreLatencyGame(),
    topology: ValidWorkTilesTestSupport.emptyTopology,
  );
}

void _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {
  final fx = owGpAdjacentMoveFixture();
  vwtExpectNoMovesToProvince(fx.game, fx.topology, fx.otherGpProvinceId);
}

void _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {
  vwtExpectBuildSuggestionsSorted([
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ]);
}

void _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  vwtExpectNoBuildSuggestionForReservedTile(
    tileKeys: [tile0, tile1],
    reservedTile: tile0,
  );
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
