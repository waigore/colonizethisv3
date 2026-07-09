// Compact getValidWorkOrderTileKeys / suggestWorkOrders assertions (Refs #3949 wave 3).

import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

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
      vwtExpectKeysEmpty(
          vwtSingleTileGame(),
          'no-such-unit',
          kWorkTargetExplore,
        );
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType:
      vwtExpectKeysEmpty(
          vwtSingleTileGame(withExplorer: true),
          'u1',
          kWorkTargetBuildImprovement,
        );
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility:
      vwtExpectKeysEmpty(
          vwtSingleTileGame(),
          'no-such-unit',
          kWorkTargetExplore,
          withVisibility: true,
        );
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility:
      vwtExpectKeysEmpty(
          vwtExplorerDisallowedBuildGame(),
          'u1',
          kWorkTargetBuildImprovement,
          withVisibility: true,
        );
    case ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation:
      final visGame = vwtColonistVisibilityFilterGame();
        final withVis = vwtVisKeys(visGame, 'u1', kWorkTargetBuildImprovement);
        final withoutVis = vwtPlainKeys(visGame, 'u1', kWorkTargetBuildImprovement);
        expect(withVis.length, withoutVis.length);
    case ValidWorkTilesTarget.buildImprovementReturnsOnlyControlledTilesWithResources:
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
              ValidWorkTilesTestSupport.provinceId('p2'): [
                foreignTileWithResource,
              ],
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
    case ValidWorkTilesTarget
        .buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      vwtExpectMineralBuildVisBeforeAfterProspect();
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
      final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
        final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
        final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        vwtExpectBuildVisMembership(
          owBuilderVisibilityGame(
            provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'minor1')],
            tilesByProvince: {
              ValidWorkTilesTestSupport.provinceId('p1'): [ownTile],
              ValidWorkTilesTestSupport.provinceId('p2'): [
                purchased,
                unpurchased,
              ],
            },
            resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
            builderTileKey: ownTile,
            improvementByTile: {purchased: 0},
            purchasedTilesByTileKey: {
              purchased: ValidWorkTilesTestSupport.playerId,
            },
            minorNations: const [
              MinorNation(id: 'minor1', displayName: 'Minor'),
            ],
          ),
          included: [purchased],
          excluded: [unpurchased],
        );
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
      final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        vwtExpectProspectVisContains(
          owTribeProspectGame(
            provinceLocalId: 'p1',
            tileKeys: [ironTile],
            resourceByTileKey: {ironTile: 'iron'},
            visibilityByTile: {ironTile: 'fogged'},
          ),
          ironTile,
        );
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      final latencyGame = owTribeExploreLatencyGame();
        final latencyTopology = ValidWorkTilesTestSupport.emptyTopology;
        final sw = Stopwatch()..start();
        final valid = validWorkTilesWithVisibility(
          game: latencyGame,
          topology: latencyTopology,
          unitId: 'u1',
          workTarget: kWorkTargetExplore,
        );
        sw.stop();
        expect(valid, isNotEmpty);
        expect(sw.elapsedMilliseconds, lessThan(1000));
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      final fx = owGpAdjacentMoveFixture();
        final view = buildPlayerView(
          fx.game,
          fx.topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final suggestions = suggestMoveOrders(
          view,
          fx.game,
          fx.topology,
          const Orders(),
        );
        expect(
          suggestions.where(
            (m) =>
                Unit.provinceIdFromTileKey(m.destinationTileKey) ==
                fx.otherGpProvinceId,
          ),
          isEmpty,
        );
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
      final tileKeys = [
          ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
          ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
          ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
        ];
        final sortGame = owGrainBuildSuggestGame(tileKeys: tileKeys);
        final sortTopology = owSingleProvinceTopology('p1');
        final buildSuggestions = suggestedWorkOrders(
          game: sortGame,
          topology: sortTopology,
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
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
        final reservedGame = owGrainBuildSuggestGame(tileKeys: [tile0, tile1]);
        final reservedTopology = owSingleProvinceTopology('p1');
        final buildSuggestions = suggestedWorkOrders(
          game: reservedGame,
          topology: reservedTopology,
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
              o.target == kWorkTargetBuildImprovement &&
              o.targetTileKey == tile0,
        );
        expect(buildSuggestions, isEmpty);
    case ValidWorkTilesTarget
        .suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut:
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
    case ValidWorkTilesTarget
        .suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
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
    case ValidWorkTilesTarget
        .suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      final prospectFx = NwPartialRevealHomeTarget.tribeGrainIron();
      vwtExpectPartialRevealSuggestions(
        fx: prospectFx,
        game: prospectFx.tribeConsulateGame('g1916p1'),
        workTarget: kWorkTargetProspect,
        expectNonEmpty: true,
        tileKey: prospectFx.t1,
      );
    case ValidWorkTilesTarget
        .suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      final ironFx = NwPartialRevealHomeTarget.tribeGrainIron(prospectedIron: true);
      vwtExpectPartialRevealSuggestions(
        fx: ironFx,
        game: ironFx.tribeConsulateGame('g1916p2'),
        workTarget: kWorkTargetProspect,
        expectNonEmpty: false,
      );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      final purchaseFx = NwPartialRevealHomeTarget.minorPurchase();
      vwtExpectPartialRevealSuggestions(
        fx: purchaseFx,
        game: purchaseFx.minorPurchaseGame(
          'g1916pl1',
          overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
        ),
        workTarget: kWorkTargetPurchaseLand,
        expectNonEmpty: true,
        provinceId: purchaseFx.provTarget,
      );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      final failPurchaseFx = NwPartialRevealHomeTarget.minorPurchase();
      vwtExpectPartialRevealSuggestions(
        fx: failPurchaseFx,
        game: failPurchaseFx.minorPurchaseGame('g1916pl2'),
        workTarget: kWorkTargetPurchaseLand,
        expectNonEmpty: false,
        provinceId: failPurchaseFx.provTarget,
      );
}
}
