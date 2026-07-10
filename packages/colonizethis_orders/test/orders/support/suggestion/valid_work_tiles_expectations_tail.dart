// Tail expectation dispatch cases (Refs #3949).

import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'valid_work_tiles_expectations.dart' show ValidWorkTilesTarget;

void runValidWorkTilesExpectationTail(ValidWorkTilesTarget target) {
  switch (target) {
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
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
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
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
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
      final reservedSuggestions = suggestedWorkOrders(
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
    default:
      throw StateError('Unexpected ValidWorkTilesTarget for tail dispatch: $target');
  }
}
