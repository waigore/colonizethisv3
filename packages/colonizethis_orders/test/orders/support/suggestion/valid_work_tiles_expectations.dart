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
    case ValidWorkTilesTarget
        .buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      vwtExpectMineralBuildGate(
          grainTile: ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
          ironTile: ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
        );
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
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
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
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
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces:
      final fx = owTribeExploreMultiProvinceFixture();
        vwtExpectVisExplore(
          game: fx.game,
          topology: ValidWorkTilesTestSupport.emptyTopology,
          includedTiles: [fx.partialKnownTile],
          excludedTiles: [fx.fullTile, fx.unknownTile],
        );
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      vwtExpectVisExploreLatencyUnder(
          game: owTribeExploreLatencyGame(),
          topology: ValidWorkTilesTestSupport.emptyTopology,
        );
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      final fx = owGpAdjacentMoveFixture();
        vwtExpectNoMovesToProvince(fx.game, fx.topology, fx.otherGpProvinceId);
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
        vwtExpectNoBuildSuggestionForReservedTile(
          tileKeys: [tile0, tile1],
          reservedTile: tile0,
        );
    case ValidWorkTilesTarget
        .suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut:
      final fx = vwtTribePartialFx();
        vwtExpectSuggestExploreTargetsProvince(
          vwtTribeConsulateGame(fx, id: 'g1916e1'),
          fx.topology(),
          fx.provTarget,
        );
    case ValidWorkTilesTarget
        .suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
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
    case ValidWorkTilesTarget
        .suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      final fx = vwtTribeGrainIronFx();
        vwtExpectSuggestProspectIncludesTile(
          vwtTribeConsulateGame(fx, id: 'g1916p1'),
          fx.topology(),
          fx.t1,
        );
    case ValidWorkTilesTarget
        .suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      final ironFx = vwtTribeGrainIronFx(prospectedIron: true);
        expect(
          vwtSuggestProspect(
            vwtTribeConsulateGame(ironFx, id: 'g1916p2'),
            ironFx.topology(),
          ),
          isEmpty,
        );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      final fx = vwtMinorPurchaseFx();
        vwtExpectPurchaseLandIncluded(
          fx,
          gameId: 'g1916pl1',
          overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
        );
    case ValidWorkTilesTarget
        .suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      vwtExpectPurchaseLandExcluded(
          vwtMinorPurchaseFx(),
          gameId: 'g1916pl2',
        );
  }
}
