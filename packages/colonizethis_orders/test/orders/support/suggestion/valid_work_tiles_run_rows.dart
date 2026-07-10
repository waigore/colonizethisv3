// Scenario run tear-offs for valid work tiles family (Refs #3949 wave 3).
import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

export 'valid_work_tiles_run_rows_tail.dart';

void vwtRunReturnsEmptyForUnknownUnitId() {
  vwtExpectKeysEmpty(vwtSingleTileGame(), 'no-such-unit', kWorkTargetExplore);
}

void vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitType() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(withExplorer: true),
    'u1',
    kWorkTargetBuildImprovement,
  );
}

void vwtRunReturnsEmptyForUnknownUnitIdWithVisibility() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(),
    'no-such-unit',
    kWorkTargetExplore,
    withVisibility: true,
  );
}

void vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(withExplorer: true),
    'u1',
    kWorkTargetBuildImprovement,
    withVisibility: true,
  );
}

void vwtRunFiltersByVisibilityBeforeOrderEngineValidation() {
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');
  final tileP1 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileP2 = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final visGame = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [vwtOwnedProvince('p1')],
      units: [
        Unit(
          id: 'u1',
          type: 'Colonist',
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: p1,
          tileKey: tileP1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      p1: [tileP1],
      p2: [tileP2],
    }),
  );
  final withVis = vwtVisKeys(visGame, 'u1', kWorkTargetBuildImprovement);
  final withoutVis = vwtPlainKeys(visGame, 'u1', kWorkTargetBuildImprovement);
  expect(withVis.length, withoutVis.length);
}

void vwtRunBuildImprovementReturnsOnlyControlledTilesWithResources() {
  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
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
    ),
    included: [tileWithResource],
    excluded: [tileWithoutResource, foreignTileWithResource],
  );
}

void
vwtRunBuildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final provinces = [vwtOwnedProvince('p1')];
  final tiles = {
    p1: [grainTile, ironTile],
  };
  final resources = {grainTile: 'grain', ironTile: 'iron'};
  final improvements = {grainTile: 0, ironTile: 0};
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
    ),
    included: [grainTile],
    excluded: [ironTile],
  );
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: provinces,
      tilesByProvince: tiles,
      resourceByTileKey: resources,
      builderTileKey: grainTile,
      improvementByTile: improvements,
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    included: [grainTile, ironTile],
  );
}

void vwtRunBuildImprovementIncludesPurchasedTilesWithResources() {
  final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
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
    ),
    included: [purchased],
    excluded: [unpurchased],
  );
}

void vwtRunBuildImprovementExcludesSeaZoneTiles() {
  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1')],
      tilesByProvince: {
        ValidWorkTilesTestSupport.provinceId('p1'): [landTile],
      },
      resourceByTileKey: {landTile: 'grain', seaTile: 'fish'},
      builderTileKey: landTile,
      improvementByTile: {landTile: 0},
      seaZoneId: seaZoneId,
      seaTiles: [seaTile],
    ),
    included: [landTile],
    excluded: [seaTile],
  );
}

void
vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {
  final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  vwtExpectProspectVisExcludesAll(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [grassTile, ironTile],
      resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
      visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {ironTile},
      },
    ),
    [grassTile, ironTile],
  );
}

void
vwtRunGetvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final prospectGame = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [ironTile],
    resourceByTileKey: {ironTile: 'iron'},
    visibilityByTile: {ironTile: 'fogged'},
  );
  expect(
    vwtVisKeys(prospectGame, 'u1', kWorkTargetProspect),
    contains(ironTile),
  );
}

void
vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  vwtExpectProspectVisExcludesAll(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [woolTile],
      resourceByTileKey: {woolTile: 'wool'},
      visibilityByTile: {woolTile: 'fogged'},
    ),
    [woolTile],
    tileMapByRegion: vwtHillsWoolTileMap('p1'),
  );
}

void
vwtRunGetvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {
  final fx = owTribeExploreMultiProvinceFixture();
  final exploreValid = validWorkTilesWithVisibility(
    game: fx.game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  for (final tile in [fx.partialKnownTile]) {
    expect(exploreValid, contains(tile));
  }
  for (final tile in [fx.fullTile, fx.unknownTile]) {
    expect(exploreValid, isNot(contains(tile)));
  }
}

void
vwtRunGetvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() {
  final latencyGame = owTribeExploreLatencyGame();
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: latencyGame,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void vwtRunSuggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {
  final moveFx = owGpAdjacentMoveFixture();
  final suggestions = suggestMoveOrders(
    buildPlayerView(
      moveFx.game,
      moveFx.topology,
      ValidWorkTilesTestSupport.playerId,
    ),
    moveFx.game,
    moveFx.topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) =>
          Unit.provinceIdFromTileKey(m.destinationTileKey) ==
          moveFx.otherGpProvinceId,
    ),
    isEmpty,
  );
}

void vwtRunSuggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {
  final tileKeys = [
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ];
  final buildSuggestions = suggestedWorkOrders(
    game: owGrainBuildSuggestGame(tileKeys: tileKeys),
    topology: owSingleProvinceTopology('p1'),
  ).where((o) => o.target == kWorkTargetBuildImprovement).toList();
  if (buildSuggestions.length > 1) {
    for (var i = 0; i < buildSuggestions.length - 1; i++) {
      expect(
        buildSuggestions[i].targetTileKey.compareTo(
          buildSuggestions[i + 1].targetTileKey,
        ),
        lessThanOrEqualTo(0),
      );
    }
  }
}

void vwtRunSuggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final reservedSuggestions =
      suggestedWorkOrders(
        game: owGrainBuildSuggestGame(tileKeys: [tile0, tile1]),
        topology: owSingleProvinceTopology('p1'),
        currentOrders: Orders(
          workOrdersByPlayerId: {
            ValidWorkTilesTestSupport.playerId: [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tile0,
              ),
            ],
          },
        ),
      ).where(
        (o) =>
            o.target == kWorkTargetBuildImprovement && o.targetTileKey == tile0,
      );
  expect(reservedSuggestions, isEmpty);
}

void
vwtRunSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  final exploreFx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  vwtExpectPartialRevealSuggestions(
    fx: exploreFx,
    game: exploreFx.tribeConsulateGame('g1916e1'),
    workTarget: kWorkTargetExplore,
    expectNonEmpty: true,
    provinceId: exploreFx.provTarget,
  );
}

void
vwtRunSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final excludeFx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  vwtExpectPartialRevealSuggestions(
    fx: excludeFx,
    game: excludeFx.game(
      id: 'g1916e2',
      players: [
        ValidWorkTilesTestSupport.defaultPlayer,
        const Player(id: 'gp2', displayName: 'P2', isHuman: false),
      ],
    ),
    workTarget: kWorkTargetExplore,
    expectNonEmpty: false,
    provinceId: excludeFx.provTarget,
  );
}

void
vwtRunSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final prospectFx = NwPartialRevealHomeTarget.tribeGrainIron();
  vwtExpectPartialRevealSuggestions(
    fx: prospectFx,
    game: prospectFx.tribeConsulateGame('g1916p1'),
    workTarget: kWorkTargetProspect,
    expectNonEmpty: true,
    tileKey: prospectFx.t1,
  );
}
