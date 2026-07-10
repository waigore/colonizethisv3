// Table-driven DefaultOrderSuggestionAPI suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_expectations.dart';

/// One row in [orderSuggestionApiImplScenarios].
class OrderSuggestionApiImplScenario implements RefsScenario {
  const OrderSuggestionApiImplScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplScenario(OrderSuggestionApiImplScenario scenario) {
  runOrderSuggestionApiImplExpectation(scenario.target);
}

List<OrderSuggestionApiImplScenario> orderSuggestionApiImplScenarios() => const [
      OrderSuggestionApiImplScenario(
        label: 'suggestMoveOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestMoveOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestWorkOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestWorkOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestBuildOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestBuildOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestBuildOrders includes ship types when player can afford a ship',
        target:
            OrderSuggestionApiImplTarget.suggestBuildOrdersIncludesShipWhenAffordable,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestResearchOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestResearchOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestNavalMoveOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestNavalMoveOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestNavalMissionOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestNavalMissionOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestNavalMoveOrders and suggestNavalMissionOrders match when caller supplies unitsById (Refs #2394)',
        target:
            OrderSuggestionApiImplTarget.navalOrdersMatchWhenCallerSuppliesUnitsById,
        refs: '#2394',
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestDiplomaticOrders returns list',
        target: OrderSuggestionApiImplTarget.suggestDiplomaticOrdersReturnsList,
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestRecruitWorkerOrders returns list (#2692 S7)',
        target: OrderSuggestionApiImplTarget.suggestRecruitWorkerOrdersReturnsList,
        refs: '#2692 S7',
      ),
      OrderSuggestionApiImplScenario(
        label: 'suggestRecruitWorkerOrders includes peasant when fabric is affordable (#2692 S7)',
        target: OrderSuggestionApiImplTarget
            .suggestRecruitWorkerOrdersIncludesPeasantWhenFabricAffordable,
        refs: '#2692 S7',
      ),
    ];
