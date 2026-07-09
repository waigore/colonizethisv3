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
          vwtMinimalSingleTileGame(),
          'no-such-unit',
          kWorkTargetExplore,
        );
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType:
      vwtExpectKeysEmpty(
          vwtExplorerSingleTileGame(),
          'u1',
          kWorkTargetBuildImprovement,
        );
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility:
      vwtExpectKeysEmpty(
          vwtMinimalSingleTileGame(),
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
      final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
        final p1 = ValidWorkTilesTestSupport.provinceId('p1');
        final provinces = [vwtOwnedProvince('p1')];
        final tiles = {p1: [grainTile, ironTile]};
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
        final excludeAllGame = owTribeProspectGame(
          provinceLocalId: 'p1',
          tileKeys: [grassTile, ironTile],
          resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
          visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
          playerProspectedTiles: {
            ValidWorkTilesTestSupport.playerId: {ironTile},
          },
        );
        final excludeAllTopology = owSingleProvinceTopology('p1');
        final excludeAllValid = validWorkTilesWithVisibility(
          game: excludeAllGame,
          topology: excludeAllTopology,
          unitId: 'u1',
          workTarget: kWorkTargetProspect,
        );
        for (final tile in [grassTile, ironTile]) {
          expect(excludeAllValid.contains(tile), isFalse);
        }
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
      final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final prospectGame = owTribeProspectGame(
          provinceLocalId: 'p1',
          tileKeys: [ironTile],
          resourceByTileKey: {ironTile: 'iron'},
          visibilityByTile: {ironTile: 'fogged'},
        );
        final prospectTopology = owSingleProvinceTopology('p1');
        expect(
          validWorkTilesWithVisibility(
            game: prospectGame,
            topology: prospectTopology,
            unitId: 'u1',
            workTarget: kWorkTargetProspect,
          ),
          contains(ironTile),
        );
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
      final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final woolGame = owTribeProspectGame(
          provinceLocalId: 'p1',
          tileKeys: [woolTile],
          resourceByTileKey: {woolTile: 'wool'},
          visibilityByTile: {woolTile: 'fogged'},
        );
        final woolTopology = owSingleProvinceTopology('p1');
        expect(
          validWorkTilesWithVisibility(
            game: woolGame,
            topology: woolTopology,
            unitId: 'u1',
            workTarget: kWorkTargetProspect,
            tileMapByRegion: vwtHillsWoolTileMap('p1'),
          ).contains(woolTile),
          isFalse,
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
      final fx = NwPartialRevealHomeTarget(
          homeLocalId: 'home',
          targetLocalId: 'tribe1',
          targetOwnerId: 'tribe1',
        );
        final exploreGame = fx.tribeConsulateGame('g1916e1');
        final exploreTopology = fx.topology();
        final explore = suggestedWorkOrders(
          game: exploreGame,
          topology: exploreTopology,
        ).where((o) => o.target == kWorkTargetExplore).toList();
        expect(explore, isNotEmpty);
        expect(
          explore.any(
            (o) =>
                Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
          ),
          isTrue,
        );
    case ValidWorkTilesTarget
        .suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
      final fx = NwPartialRevealHomeTarget(
          homeLocalId: 'home',
          targetLocalId: 'gp2p',
          targetOwnerId: 'gp2',
        );
        final excludeGame = fx.game(
          id: 'g1916e2',
          players: [
            ValidWorkTilesTestSupport.defaultPlayer,
            const Player(id: 'gp2', displayName: 'P2', isHuman: false),
          ],
        );
        final excludeTopology = fx.topology();
        expect(
          suggestedWorkOrders(
            game: excludeGame,
            topology: excludeTopology,
          ).where((o) => o.target == kWorkTargetExplore).where(
            (o) =>
                Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
          ),
          isEmpty,
        );
    case ValidWorkTilesTarget
        .suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      final fx = NwPartialRevealHomeTarget.tribeGrainIron();
        final prospectGame = fx.tribeConsulateGame('g1916p1');
        final prospectTopology = fx.topology();
        final prospect = suggestedWorkOrders(
          game: prospectGame,
          topology: prospectTopology,
        ).where((o) => o.target == kWorkTargetProspect).toList();
        expect(prospect, isNotEmpty);
        expect(prospect.any((o) => o.targetTileKey == fx.t1), isTrue);
    case ValidWorkTilesTarget
        .suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      final ironFx = NwPartialRevealHomeTarget.tribeGrainIron(prospectedIron: true);
        expect(
          suggestedWorkOrders(
            game: ironFx.tribeConsulateGame('g1916p2'),
            topology: ironFx.topology(),
          ).where((o) => o.target == kWorkTargetProspect),
          isEmpty,
        );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      final fx = NwPartialRevealHomeTarget.minorPurchase();
        expect(
          suggestedWorkOrders(
            game: fx.minorPurchaseGame(
              'g1916pl1',
              overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
            ),
            topology: fx.topology(),
          ).where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
          ),
          isNotEmpty,
        );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      final purchaseFx = NwPartialRevealHomeTarget.minorPurchase();
        expect(
          suggestedWorkOrders(
            game: purchaseFx.minorPurchaseGame('g1916pl2'),
            topology: purchaseFx.topology(),
          ).where(
            (o) =>
                o.target == kWorkTargetPurchaseLand &&
                Unit.provinceIdFromTileKey(o.targetTileKey) ==
                    purchaseFx.provTarget,
          ),
          isEmpty,
        );
  }
}
