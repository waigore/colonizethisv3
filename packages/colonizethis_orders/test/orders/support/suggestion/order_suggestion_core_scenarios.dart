// Table-driven order_suggestion_core scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_core_expectations.dart';

/// One row in [orderSuggestionCoreScenarios].
class OrderSuggestionCoreScenario implements RefsScenario {
  const OrderSuggestionCoreScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionCoreTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionCoreScenario(OrderSuggestionCoreScenario scenario) {
  runOrderSuggestionCoreExpectation(scenario.target);
}

/// Canonical scenarios for order_suggestion_core family tests.
/// Labels match former part-file descriptions (joined onto one line for CI).
List<OrderSuggestionCoreScenario> orderSuggestionCoreScenarios() => const [
  OrderSuggestionCoreScenario(
    label: 'suggestMoveOrders only returns moves that pass validation',
    target: OrderSuggestionCoreTarget
        .suggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestMoveOrders throws when source province has unknown visibility',
    target: OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  ),
  OrderSuggestionCoreScenario(
    label:
        'move suggestions use unit locationProvinceId (tileKey-derived for civilians)',
    target: OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  ),
  OrderSuggestionCoreScenario(
    label: 'no explore suggestion when province unknown',
    target: OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestWorkOrders explore target uses kWorkTargetExplore',
    target: OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders explore aligns with partially revealed province cache scope',
    target: OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  ),
  OrderSuggestionCoreScenario(
    label: 'no prospect suggestion when province not at least fogged',
    target: OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged,
  ),
  OrderSuggestionCoreScenario(
    label: 'prospect suggestion when province fogged and tiles in province',
    target: OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince,
  ),
  OrderSuggestionCoreScenario(
    label:
        'PlayerView.provincesById matches allProvinces for prospect iteration order',
    target: OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  ),
  OrderSuggestionCoreScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility excludes tile reserved by another unit pending order',
    target: OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  ),
  OrderSuggestionCoreScenario(
    label:
        'work suggestions for worker use unit id; targets may be any valid tile',
    target: OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders includes build_improvement when first province tile has no resource but a later tile does',
    target: OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders includes build_improvement on another owned province when the builder’s province has no valid resource tile',
    target: OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestWorkOrders second Builder skips tile reserved by another Builder pending work order',
    target: OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestNavalMissionOrders returns list',
    target: OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestBuildOrders returns list',
    target: OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestBuildOrders returns ship when affordable',
    target:
        OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable,
  ),
  OrderSuggestionCoreScenario(
    label:
        'suggestBuildOrders can return both regiment and ship when both affordable',
    target: OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestResearchOrders returns list',
    target: OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'suggestNavalMoveOrders returns list',
    target: OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList,
  ),
  OrderSuggestionCoreScenario(
    label: 'counter_spy work suggested for Spy in owned province with tiles',
    target: OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  ),
  OrderSuggestionCoreScenario(
    label:
        'purchase_land work suggested for Merchant when minor province has resource tile',
    target: OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
  ),
];
