// Table-driven army-move heuristics suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_heuristics_expectations.dart';

/// One row in [orderSuggestionArmyMoveHeuristicsScenarios].
class OrderSuggestionArmyMoveHeuristicsScenario implements RefsScenario {
  const OrderSuggestionArmyMoveHeuristicsScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionArmyMoveHeuristicsTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionArmyMoveHeuristicsScenario(
  OrderSuggestionArmyMoveHeuristicsScenario scenario,
) {
  runOrderSuggestionArmyMoveHeuristicsExpectation(scenario.target);
}

List<OrderSuggestionArmyMoveHeuristicsScenario>
    orderSuggestionArmyMoveHeuristicsScenarios() => const [
          OrderSuggestionArmyMoveHeuristicsScenario(
            label: 'keeps at most one army move per army id',
            target: OrderSuggestionArmyMoveHeuristicsTarget
                .keepsAtMostOneArmyMovePerArmyId,
          ),
        ];
