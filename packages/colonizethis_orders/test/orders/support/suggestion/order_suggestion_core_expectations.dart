// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

part 'order_suggestion_core_expectations_part1.dart';
part 'order_suggestion_core_expectations_part2.dart';

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
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      runOrderSuggestionCoreExpectationPart1(target);
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      runOrderSuggestionCoreExpectationPart2(target);
  }
}
