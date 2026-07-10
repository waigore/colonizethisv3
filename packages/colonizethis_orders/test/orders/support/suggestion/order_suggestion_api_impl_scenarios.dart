// Table-driven DefaultOrderSuggestionAPI suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_run_rows.dart';

/// One row in [orderSuggestionApiImplScenarios].
class OrderSuggestionApiImplScenario implements RefsScenario {
  const OrderSuggestionApiImplScenario({
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

void runOrderSuggestionApiImplScenario(
  OrderSuggestionApiImplScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplScenario>
orderSuggestionApiImplScenarios() => const [
  OrderSuggestionApiImplScenario(
    label: 'suggestMoveOrders returns list',
    run: osaiRunSuggestMoveOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestWorkOrders returns list',
    run: osaiRunSuggestWorkOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestBuildOrders returns list',
    run: osaiRunSuggestBuildOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label:
        'suggestBuildOrders includes ship types when player can afford a ship',
    run: osaiRunSuggestBuildOrdersIncludesShipWhenAffordable,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestResearchOrders returns list',
    run: osaiRunSuggestResearchOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestNavalMoveOrders returns list',
    run: osaiRunSuggestNavalMoveOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestNavalMissionOrders returns list',
    run: osaiRunSuggestNavalMissionOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label:
        'suggestNavalMoveOrders and suggestNavalMissionOrders match when caller supplies unitsById (Refs #2394)',
    run: osaiRunNavalOrdersMatchWhenCallerSuppliesUnitsById,
    refs: '#2394',
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestDiplomaticOrders returns list',
    run: osaiRunSuggestDiplomaticOrdersReturnsList,
  ),
  OrderSuggestionApiImplScenario(
    label: 'suggestRecruitWorkerOrders returns list (#2692 S7)',
    run: osaiRunSuggestRecruitWorkerOrdersReturnsList,
    refs: '#2692 S7',
  ),
  OrderSuggestionApiImplScenario(
    label:
        'suggestRecruitWorkerOrders includes peasant when fabric is affordable (#2692 S7)',
    run: osaiRunSuggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable,
    refs: '#2692 S7',
  ),
];
