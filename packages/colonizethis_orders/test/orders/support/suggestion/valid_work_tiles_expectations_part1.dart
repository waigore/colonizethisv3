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
  expect(
    vwtPlainKeys(vwtMinimalSingleTileGame(), 'no-such-unit', kWorkTargetExplore),
    isEmpty,
  );
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitType() {
  expect(
    vwtPlainKeys(
      vwtExplorerSingleTileGame(),
      'u1',
      kWorkTargetBuildImprovement,
    ),
    isEmpty,
  );
}

void _returnsEmptyForUnknownUnitIdWithVisibility() {
  expect(
    vwtVisKeys(vwtMinimalSingleTileGame(), 'no-such-unit', kWorkTargetExplore),
    isEmpty,
  );
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility() {
  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [_ownedProvince('p1')],
      units: [
        ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: tile,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      provinceId: [tile],
    }),
  );
  expect(
    vwtVisKeys(game, 'u1', kWorkTargetBuildImprovement),
    isEmpty,
  );
}

void _filtersByVisibilityBeforeOrderEngineValidation() {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');
  final tileP1 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileP2 = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unit = Unit(
    id: 'u1',
    type: 'Colonist',
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: p1,
    tileKey: tileP1,
  );
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [_ownedProvince('p1')],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        p1: [tileP1],
        p2: [tileP2],
      },
    ),
  );
  final withVis = vwtVisKeys(game, 'u1', kWorkTargetBuildImprovement);
  final withoutVis = vwtPlainKeys(game, 'u1', kWorkTargetBuildImprovement);
  expect(withVis.length, withoutVis.length);
}

void _buildImprovementReturnsOnlyControlledTilesWithResources() {
  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1'), _province('p2', 'other')],
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
  );
  final valid = vwtBuildVisKeys(game);
  expect(valid.contains(tileWithResource), isTrue);
  expect(valid.contains(tileWithoutResource), isFalse);
  expect(valid.contains(foreignTileWithResource), isFalse);
}

void _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tiles = {p1: [grainTile, ironTile]};
  final resources = {grainTile: 'grain', ironTile: 'iron'};
  final improvements = {grainTile: 0, ironTile: 0};
  final provinces = [_ownedProvince('p1')];

  final unprospected = owBuilderVisibilityGame(
    provinces: provinces,
    tilesByProvince: tiles,
    resourceByTileKey: resources,
    builderTileKey: grainTile,
    improvementByTile: improvements,
  );
  final validUnprospected = vwtBuildVisKeys(unprospected);
  expect(validUnprospected.contains(grainTile), isTrue);
  expect(validUnprospected.contains(ironTile), isFalse);

  final prospected = owBuilderVisibilityGame(
    provinces: provinces,
    tilesByProvince: tiles,
    resourceByTileKey: resources,
    builderTileKey: grainTile,
    improvementByTile: improvements,
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {ironTile},
    },
  );
  final validProspected = vwtBuildVisKeys(prospected);
  expect(validProspected.contains(grainTile), isTrue);
  expect(validProspected.contains(ironTile), isTrue);
}

void _buildImprovementIncludesPurchasedTilesWithResources() {
  final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1'), _province('p2', 'minor1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [ownTile],
      ValidWorkTilesTestSupport.provinceId('p2'): [purchased, unpurchased],
    },
    resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
    builderTileKey: ownTile,
    purchasedTilesByTileKey: {
      purchased: ValidWorkTilesTestSupport.playerId,
    },
    improvementByTile: {purchased: 0},
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
  );
  final valid = vwtBuildVisKeys(game);
  expect(valid.contains(purchased), isTrue);
  expect(valid.contains(unpurchased), isFalse);
}

void _buildImprovementExcludesSeaZoneTiles() {
  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [landTile],
    },
    resourceByTileKey: {landTile: 'grain', seaTile: 'fish'},
    builderTileKey: landTile,
    improvementByTile: {landTile: 0},
    seaZoneId: seaZoneId,
    seaTiles: [seaTile],
  );
  final valid = vwtBuildVisKeys(game);
  expect(valid.contains(landTile), isTrue);
  expect(valid.contains(seaTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {
  final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [grassTile, ironTile],
    resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
    visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {ironTile},
    },
  );
  final topology = owSingleProvinceTopology('p1');
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
  );
  expect(valid.contains(grassTile), isFalse);
  expect(valid.contains(ironTile), isFalse);
}
