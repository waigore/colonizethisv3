// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'order_suggestion_core_expectation_shorthand.dart';

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
      oscExpectFoggedDestinationFirstMove();
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      oscExpectMoveThrowsOnUnknownSourceVisibility();
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      oscExpectMislocatedExplorerMoveUsesTileProvince();
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      oscExpectNoExploreWhenProvinceUnknown();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      oscExpectFoggedExploreSuggestion();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      oscExpectPartialRevealExploreCacheAligned();
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      oscExpectNoProspectWhenProvinceNotFogged();
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      oscExpectFoggedProspectTargetsIron();
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      oscExpectProvinceViewForProspectIteration();
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
      oscExpectDualBuilderVisKeysExcludeReservedGrainTiles();
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      oscExpectWorkerSuggestStayInBuilderProvince();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      oscExpectBuildImprovementOnSecondTileInProvince();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      oscExpectBuildImprovementOnOtherOwnedProvince();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      oscExpectDualBuilderSuggestSkipsReservedGrainTiles();
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
      oscExpectNavalMissionSuggestList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
      oscExpectCapitalBuildSuggestDefaultList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
      oscExpectAffordableShipBuildSuggestions();
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      oscExpectAffordableRegimentAndShipBuildSuggestions();
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      oscExpectResearchSuggestList();
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      oscExpectNavalMoveSuggestList();
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      oscExpectCounterSpyOnOwnedProvince();
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      oscExpectMerchantPurchaseLandWorkSuggested();
  }
}
