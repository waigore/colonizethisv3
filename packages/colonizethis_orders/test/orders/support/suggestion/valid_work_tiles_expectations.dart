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
      vwtExpectControlledTilesWithResourcesOnly();
    case ValidWorkTilesTarget
        .buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      vwtExpectMineralBuildVisBeforeAfterProspect();
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
      vwtExpectPurchasedTilesIncluded();
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
      vwtExpectSeaZoneExcludedFromBuild();
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
      vwtExpectExplorePartialProvinceScan();
    case ValidWorkTilesTarget
        .getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      vwtExpectExploreLatencyUnderOneSecond();
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      vwtExpectMoveExcludesGpProvince();
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
      vwtExpectBuildSuggestSortedByTileKey();
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      vwtExpectBuildSuggestExcludesReservedTile();
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
