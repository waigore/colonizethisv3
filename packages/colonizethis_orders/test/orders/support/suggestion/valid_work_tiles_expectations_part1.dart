part of 'valid_work_tiles_expectations.dart';

void runValidWorkTilesExpectation(ValidWorkTilesTarget target) {
  switch (target) {
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitId:
      _returnsEmptyForUnknownUnitId();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType:
      _returnsEmptyWhenWorkTargetNotAllowedForUnitType();
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility:
      _returnsEmptyForUnknownUnitIdWithVisibility();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility:
      _returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility();
    case ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation:
      _filtersByVisibilityBeforeOrderEngineValidation();
    case ValidWorkTilesTarget.buildImprovementReturnsOnlyControlledTilesWithResources:
      _buildImprovementReturnsOnlyControlledTilesWithResources();
    case ValidWorkTilesTarget.buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected();
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
      _buildImprovementIncludesPurchasedTilesWithResources();
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
      _buildImprovementExcludesSeaZoneTiles();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected:
      _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
      _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
      _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces:
      _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture();
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces();
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
      _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch();
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit();
    case ValidWorkTilesTarget.suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut:
      _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut();
    case ValidWorkTilesTarget.suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
      _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation();
    case ValidWorkTilesTarget.suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile();
    case ValidWorkTilesTarget.suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral();
    case ValidWorkTilesTarget.suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy();
    case ValidWorkTilesTarget.suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail();
  }
}

void _returnsEmptyForUnknownUnitId() {
  vwtExpectKeysEmpty(
    vwtMinimalSingleTileGame(),
    'no-such-unit',
    kWorkTargetExplore,
  );
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitType() {
  vwtExpectKeysEmpty(
    vwtExplorerSingleTileGame(),
    'u1',
    kWorkTargetBuildImprovement,
  );
}

void _returnsEmptyForUnknownUnitIdWithVisibility() {
  vwtExpectKeysEmpty(
    vwtMinimalSingleTileGame(),
    'no-such-unit',
    kWorkTargetExplore,
    withVisibility: true,
  );
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility() {
  vwtExpectKeysEmpty(
    vwtExplorerDisallowedBuildGame(),
    'u1',
    kWorkTargetBuildImprovement,
    withVisibility: true,
  );
}

void _filtersByVisibilityBeforeOrderEngineValidation() {
  vwtExpectVisMatchesPlain(
    vwtColonistVisibilityFilterGame(),
    'u1',
    kWorkTargetBuildImprovement,
  );
}

void _buildImprovementReturnsOnlyControlledTilesWithResources() {
  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  vwtExpectBuildResourceFilter(
    provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'other')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [
        tileWithResource,
        tileWithoutResource,
      ],
      ValidWorkTilesTestSupport.provinceId('p2'): [foreignTileWithResource],
    },
    resourceByTileKey: {
      tileWithResource: 'grain',
      foreignTileWithResource: 'iron',
    },
    builderTileKey: tileWithResource,
    improvementByTile: {tileWithResource: 0},
    extraPlayers: const [
      Player(id: 'other', displayName: 'Other', isHuman: false),
    ],
    included: [tileWithResource],
    excluded: [tileWithoutResource, foreignTileWithResource],
  );
}

void _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  vwtExpectMineralBuildGate(grainTile: grainTile, ironTile: ironTile);
}

void _buildImprovementIncludesPurchasedTilesWithResources() {
  final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectBuildResourceFilter(
    provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'minor1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [ownTile],
      ValidWorkTilesTestSupport.provinceId('p2'): [purchased, unpurchased],
    },
    resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
    builderTileKey: ownTile,
    improvementByTile: {purchased: 0},
    purchasedTilesByTileKey: {purchased: ValidWorkTilesTestSupport.playerId},
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    included: [purchased],
    excluded: [unpurchased],
  );
}

void _buildImprovementExcludesSeaZoneTiles() {
  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  vwtExpectBuildResourceFilter(
    provinces: [vwtOwnedProvince('p1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [landTile],
    },
    resourceByTileKey: {landTile: 'grain', seaTile: 'fish'},
    builderTileKey: landTile,
    improvementByTile: {landTile: 0},
    seaZoneId: seaZoneId,
    seaTiles: [seaTile],
    included: [landTile],
    excluded: [seaTile],
  );
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {
  final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  vwtExpectVisProspectExcludesAll(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [grassTile, ironTile],
      resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
      visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    owSingleProvinceTopology('p1'),
    [grassTile, ironTile],
  );
}
