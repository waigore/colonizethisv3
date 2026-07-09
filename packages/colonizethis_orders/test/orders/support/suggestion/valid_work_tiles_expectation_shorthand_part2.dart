part of 'valid_work_tiles_expectation_shorthand.dart';

void vwtExpectPartialRevealProspectIncluded() {
  final fx = vwtTribeGrainIronFx();
  vwtExpectSuggestProspectIncludesTile(
    vwtTribeConsulateGame(fx, id: 'g1916p1'),
    fx.topology(),
    fx.t1,
  );
}

void vwtExpectNoBuildSuggestionForReservedTile({
  required List<String> tileKeys,
  required String reservedTile,
}) {
  final game = owGrainBuildSuggestGame(tileKeys: tileKeys);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(
    game: game,
    topology: topology,
    currentOrders: Orders(
      workOrdersByPlayerId: {
        ValidWorkTilesTestSupport.playerId: [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: reservedTile,
          ),
        ],
      },
    ),
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == reservedTile,
  );
  expect(buildSuggestions, isEmpty);
}

void vwtExpectControlledTilesWithResourcesOnly() {
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

void vwtExpectPurchasedTileIncluded() {
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

void vwtExpectSeaZoneTileExcluded() {
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

void vwtExpectProspectExcludedWhenIronProspected(NwPartialRevealHomeTarget fx) {
  expect(
    vwtSuggestProspect(
      vwtTribeConsulateGame(fx, id: 'g1916p2'),
      fx.topology(),
    ),
    isEmpty,
  );
}

void vwtExpectPurchaseLandIncluded(
  NwPartialRevealHomeTarget fx, {
  required String gameId,
  List<OvertureState>? overtureStates,
}) {
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(
        fx,
        id: gameId,
        overtureStates: overtureStates,
      ),
      fx.topology(),
      fx.provTarget,
    ),
    isNotEmpty,
  );
}

void vwtExpectPurchaseLandExcluded(
  NwPartialRevealHomeTarget fx, {
  required String gameId,
}) {
  expect(
    vwtSuggestPurchaseLand(
      vwtMinorPurchaseGame(fx, id: gameId),
      fx.topology(),
      fx.provTarget,
    ),
    isEmpty,
  );
}

void vwtExpectVisProspectExcludesGrassAndProspectedIron({
  String provinceLocalId = 'p1',
}) {
  final grassTile = ValidWorkTilesTestSupport.tileKey(provinceLocalId, 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey(provinceLocalId, 1, 0);
  vwtExpectVisProspectExcludesAll(
    owTribeProspectGame(
      provinceLocalId: provinceLocalId,
      tileKeys: [grassTile, ironTile],
      resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
      visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    owSingleProvinceTopology(provinceLocalId),
    [grassTile, ironTile],
  );
}

void vwtExpectVisProspectIncludesEligibleIronTile({
  String provinceLocalId = 'p1',
}) {
  final ironTile = ValidWorkTilesTestSupport.tileKey(provinceLocalId, 0, 0);
  vwtExpectVisProspectContains(
    owTribeProspectGame(
      provinceLocalId: provinceLocalId,
      tileKeys: [ironTile],
      resourceByTileKey: {ironTile: 'iron'},
      visibilityByTile: {ironTile: 'fogged'},
    ),
    owSingleProvinceTopology(provinceLocalId),
    ironTile,
  );
}

void vwtExpectVisProspectExcludesWoolOnHillsTerrain({
  String provinceLocalId = 'p1',
}) {
  final woolTile = ValidWorkTilesTestSupport.tileKey(provinceLocalId, 0, 0);
  vwtExpectVisProspectExcludes(
    owTribeProspectGame(
      provinceLocalId: provinceLocalId,
      tileKeys: [woolTile],
      resourceByTileKey: {woolTile: 'wool'},
      visibilityByTile: {woolTile: 'fogged'},
    ),
    owSingleProvinceTopology(provinceLocalId),
    woolTile,
    tileMapByRegion: vwtHillsWoolTileMap(provinceLocalId),
  );
}

void vwtExpectVisExplorePartialProvincesOnly() {
  final fx = owTribeExploreMultiProvinceFixture();
  vwtExpectVisExplore(
    game: fx.game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    includedTiles: [fx.partialKnownTile],
    excludedTiles: [fx.fullTile, fx.unknownTile],
  );
}

void vwtExpectVisExploreLargeMapUnderOneSecond() {
  vwtExpectVisExploreLatencyUnder(
    game: owTribeExploreLatencyGame(),
    topology: ValidWorkTilesTestSupport.emptyTopology,
  );
}

void vwtExpectNoMovesToOtherGpProvince() {
  final fx = owGpAdjacentMoveFixture();
  vwtExpectNoMovesToProvince(fx.game, fx.topology, fx.otherGpProvinceId);
}

void vwtExpectBuildSuggestionsSortedThreeTiles() {
  vwtExpectBuildSuggestionsSorted([
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ]);
}

void vwtExpectNoBuildForReservedTilePair() {
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  vwtExpectNoBuildSuggestionForReservedTile(
    tileKeys: [tile0, tile1],
    reservedTile: tile0,
  );
}

void vwtExpectMinorPurchaseLandIncludedWithEmbassy() {
  final fx = vwtMinorPurchaseFx();
  vwtExpectPurchaseLandIncluded(
    fx,
    gameId: 'g1916pl1',
    overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
  );
}

void vwtExpectMinorPurchaseLandExcludedWithoutEmbassy() {
  vwtExpectPurchaseLandExcluded(
    vwtMinorPurchaseFx(),
    gameId: 'g1916pl2',
  );
}

void vwtExpectOwnedMineralBuildGateDefaultTiles() {
  vwtExpectMineralBuildGate(
    grainTile: ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ironTile: ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
  );
}
