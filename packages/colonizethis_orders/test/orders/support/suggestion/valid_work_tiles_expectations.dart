// Compact getValidWorkOrderTileKeys / suggestWorkOrders assertions (Refs #3949 wave 3).

import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_expectations_tail.dart';
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
          vwtSingleTileGame(withExplorer: true),
          'u1',
          kWorkTargetBuildImprovement,
          withVisibility: true,
        );
    case ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation:
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
            ValidWorkTilesTestSupport.provinceId('p2'): [purchased, unpurchased],
          },
          resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
          builderTileKey: ownTile,
          improvementByTile: {purchased: 0},
          purchasedTilesByTileKey: {
            purchased: ValidWorkTilesTestSupport.playerId,
          },
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
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
    default:
      runValidWorkTilesExpectationTail(target);
  }
}
