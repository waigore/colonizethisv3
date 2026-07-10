// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_core_run_rows.dart';

class OrderSuggestionCoreScenario implements RefsScenario {
  const OrderSuggestionCoreScenario({
    required this.label,
    required this.run,
    this.refs,
  });
  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionCoreScenario(OrderSuggestionCoreScenario scenario) =>
    scenario.run();

List<OrderSuggestionCoreScenario> orderSuggestionCoreScenarios() => [
  OrderSuggestionCoreScenario(
    label: 'suggestMoveOrders only returns moves that pass validation',
    run: oscRunSuggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestMoveOrders throws when source province has unknown visibility',
    run: oscRunSuggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  ),
  OrderSuggestionCoreScenario(
    label:
        'move suggestions use unit locationProvinceId (tileKey-derived for civilians)',
    run:
        oscRunMoveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  ),
  OrderSuggestionCoreScenario(
    label: 'no explore suggestion when province unknown',
    run: oscRunNoExploreSuggestionWhenProvinceUnknown,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestWorkOrders explore target uses kWorkTargetExplore',
    run: oscRunSuggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders explore aligns with partially revealed province cache scope',
    run:
        oscRunSuggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  ),
  OrderSuggestionCoreScenario(
    label: 'no prospect suggestion when province not at least fogged',
    run: oscRunNoProspectSuggestionWhenProvinceNotAtLeastFogged,
  ),
  OrderSuggestionCoreScenario(
    label: 'prospect suggestion when province fogged and tiles in province',
    run: oscRunProspectSuggestionWhenProvinceFoggedAndTilesInProvince,
  ),
  OrderSuggestionCoreScenario(
    label:
        'PlayerView.provincesById matches allProvinces for prospect iteration order',
    run:
        oscRunPlayerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  ),
  OrderSuggestionCoreScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility excludes tile reserved by another unit pending order',
    run:
        oscRunGetValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  ),
  OrderSuggestionCoreScenario(
    label:
        'work suggestions for worker use unit id; targets may be any valid tile',
    run: oscRunWorkSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders includes build_improvement when first province tile has no resource but a later tile does',
    run:
        oscRunSuggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders includes build_improvement on another owned province when the builder’s province has no valid resource tile',
    run:
        oscRunSuggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders second Builder skips tile reserved by another Builder pending work order',
    run:
        oscRunSuggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestNavalMissionOrders returns list',
    run: oscRunSuggestNavalMissionOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestBuildOrders returns list',
    run: oscRunSuggestBuildOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestBuildOrders returns ship when affordable',
    run: oscRunSuggestBuildOrdersReturnsShipWhenAffordable,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestBuildOrders can return both regiment and ship when both affordable',
    run: oscRunSuggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestResearchOrders returns list',
    run: oscRunSuggestResearchOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestNavalMoveOrders returns list',
    run: oscRunSuggestNavalMoveOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'counter_spy work suggested for Spy in owned province with tiles',
    run: oscRunCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  ),
  OrderSuggestionCoreScenario(
    label:
        'purchase_land work suggested for Merchant when minor province has resource tile',
    run:
        oscRunPurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
  ),
];
