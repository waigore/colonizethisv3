// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Pins for [orderSuggestionCoreScenarios] rows.
enum OrderSuggestionCoreTarget {
  suggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  noExploreSuggestionWhenProvinceUnknown,
  suggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  noProspectSuggestionWhenProvinceNotAtLeastFogged,
  prospectSuggestionWhenProvinceFoggedAndTilesInProvince,
  playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  suggestNavalMissionOrdersReturnsList,
  suggestBuildOrdersReturnsList,
  suggestBuildOrdersReturnsShipWhenAffordable,
  suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  suggestResearchOrdersReturnsList,
  suggestNavalMoveOrdersReturnsList,
  counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
}

void runOrderSuggestionCoreExpectation(OrderSuggestionCoreTarget target) {
  switch (target) {
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersOnlyReturnsMovesThatPassValidation:
      oscExpectMovePassesValidationToAdjacentProvince();
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      oscExpectMoveThrowsWhenSourceProvinceUnknown();
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      oscExpectCivilianMoveUsesTileKeyDerivedLocation();
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetExplore,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      oscExpectExploreTargetUsesExplore();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      oscExpectPartialRevealExploreCacheScope();
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      oscExpectWorkTargetSuggestions(
        game: oscExplorerProvinceGame(
          ownerId: 'tribe1',
          visibilityByTile: {OscIds.tile('p1', 0, 0): 'unknown'},
        ),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetProspect,
        expectNonEmpty: false,
      );
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      final tileKey = OscIds.tile('p1', 0, 0);
        oscExpectWorkTargetSuggestions(
          game: oscGame(
            worldState: oscExplorerProvinceGame(
              visibilityByTile: {tileKey: 'fogged'},
              tilesByLocal: {'p1': [tileKey]},
            ).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),
          ),
          topology: oscProvinceTopology(['p1']),
          target: kWorkTargetProspect,
          expectNonEmpty: true,
          expectedTileKey: tileKey,
        );
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      oscExpectProvinceViewMatchesAllForProspect();
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
      oscExpectReservedTileExcludedFromValidKeys();
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      oscExpectWorkerSuggestionsUseUnitLocation();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      final tileNoResource = OscIds.tile('p1', 0, 0);
        final tileWithResource = OscIds.tile('p1', 1, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileNoResource,
            tileWithResource: tileWithResource,
          ),
          topology: oscProvinceTopology(['p1']),
          expectedTileKey: tileWithResource,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      final tileP1 = OscIds.tile('p1', 0, 0);
        final tileP2 = OscIds.tile('p2', 0, 0);
        oscExpectBuildImprovementFirstTile(
          game: oscBuilderImprovementGame(
            tileNoResource: tileP1,
            tileWithResource: tileP2,
            secondProvinceLocal: 'p2',
            secondTile: tileP2,
          ),
          topology: oscProvinceTopology(['p1', 'p2']),
          expectedTileKey: tileP2,
          unitId: 'u1',
        );
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      final setup = OscDualBuilderGrainTiles();
        oscExpectBuildImprovementFirstTile(
          game: setup.game(),
          topology: setup.topology(),
          expectedTileKey: setup.tileB,
          orders: setup.ordersReservingTileA(),
        );
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
      oscExpectNavalMissionOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
      oscExpectBuildOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
      oscExpectBuildOrdersReturnsShipWhenAffordable();
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      oscExpectBothRegimentAndShipWhenAffordable();
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      oscExpectResearchOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      oscExpectNavalMoveOrdersReturnsList();
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      oscExpectWorkTargetSuggestions(
        game: oscSpyCounterSuggestGame(),
        topology: oscProvinceTopology(['p1']),
        target: kWorkTargetCounterSpy,
        expectNonEmpty: true,
      );
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      oscExpectWorkTargetSuggestions(
        game: oscMerchantPurchaseLandSuggestGame(),
        topology: oscProvinceTopology(['p1', 'minor1']),
        target: kWorkTargetPurchaseLand,
        expectNonEmpty: true,
      );
}
}
