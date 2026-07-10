// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_core_run_rows.dart';

List<RunnableScenario> orderSuggestionCoreScenarios() => [
  RunnableScenario(
    label: 'suggestMoveOrders only returns moves that pass validation',
    run: oscRunSuggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  ),
  RunnableScenario(
    label:
        'suggestMoveOrders throws when source province has unknown visibility',
    run: oscRunSuggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  ),
  RunnableScenario(
    label:
        'move suggestions use unit locationProvinceId (tileKey-derived for civilians)',
    run:
        oscRunMoveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  ),
  RunnableScenario(
    label: 'no explore suggestion when province unknown',
    run: oscRunNoExploreSuggestionWhenProvinceUnknown,
  ),
  RunnableScenario(
    label: 'suggestWorkOrders explore target uses kWorkTargetExplore',
    run: oscRunSuggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders explore aligns with partially revealed province cache scope',
    run:
        oscRunSuggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  ),
  RunnableScenario(
    label: 'no prospect suggestion when province not at least fogged',
    run: oscRunNoProspectSuggestionWhenProvinceNotAtLeastFogged,
  ),
  RunnableScenario(
    label: 'prospect suggestion when province fogged and tiles in province',
    run: oscRunProspectSuggestionWhenProvinceFoggedAndTilesInProvince,
  ),
  RunnableScenario(
    label:
        'PlayerView.provincesById matches allProvinces for prospect iteration order',
    run:
        oscRunPlayerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility excludes tile reserved by another unit pending order',
    run:
        oscRunGetValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  ),
  RunnableScenario(
    label:
        'work suggestions for worker use unit id; targets may be any valid tile',
    run: oscRunWorkSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders includes build_improvement when first province tile has no resource but a later tile does',
    run:
        oscRunSuggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders includes build_improvement on another owned province when the builder’s province has no valid resource tile',
    run:
        oscRunSuggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders second Builder skips tile reserved by another Builder pending work order',
    run:
        oscRunSuggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  ),
  RunnableScenario(
    label: 'suggestNavalMissionOrders returns list',
    run: oscRunSuggestNavalMissionOrdersReturnsList,
  ),
  RunnableScenario(
    label: 'suggestBuildOrders returns list',
    run: oscRunSuggestBuildOrdersReturnsList,
  ),
  RunnableScenario(
    label: 'suggestBuildOrders returns ship when affordable',
    run: oscRunSuggestBuildOrdersReturnsShipWhenAffordable,
  ),
  RunnableScenario(
    label:
        'suggestBuildOrders can return both regiment and ship when both affordable',
    run: oscRunSuggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  ),
  RunnableScenario(
    label: 'suggestResearchOrders returns list',
    run: oscRunSuggestResearchOrdersReturnsList,
  ),
  RunnableScenario(
    label: 'suggestNavalMoveOrders returns list',
    run: oscRunSuggestNavalMoveOrdersReturnsList,
  ),
  RunnableScenario(
    label: 'counter_spy work suggested for Spy in owned province with tiles',
    run: oscRunCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  ),
  RunnableScenario(
    label:
        'purchase_land work suggested for Merchant when minor province has resource tile',
    run:
        oscRunPurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
  ),
];
