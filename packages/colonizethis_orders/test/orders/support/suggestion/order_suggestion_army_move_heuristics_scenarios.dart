// Table-driven army-move heuristics suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_heuristics_run_rows.dart';

/// One row in [orderSuggestionArmyMoveHeuristicsScenarios].
class OrderSuggestionArmyMoveHeuristicsScenario implements RefsScenario {
  const OrderSuggestionArmyMoveHeuristicsScenario({
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

void runOrderSuggestionArmyMoveHeuristicsScenario(
  OrderSuggestionArmyMoveHeuristicsScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionArmyMoveHeuristicsScenario>
orderSuggestionArmyMoveHeuristicsScenarios() => const [
  OrderSuggestionArmyMoveHeuristicsScenario(
    label: 'keeps at most one army move per army id',
    run: osamhRunKeepsAtMostOneArmyMovePerArmyId,
  ),
];
