// Table-driven diplomatic-pass suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_pass_expectations.dart';

/// One row in diplomatic-pass suggestion scenario tables.
class OrderSuggestionDiplomaticPassScenario implements RefsScenario {
  const OrderSuggestionDiplomaticPassScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDiplomaticPassTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDiplomaticPassScenario(
  OrderSuggestionDiplomaticPassScenario scenario,
) {
  runOrderSuggestionDiplomaticPassExpectation(scenario.target);
}

List<OrderSuggestionDiplomaticPassScenario> orderSuggestionDiplomaticPassScenarios() =>
    const [
      OrderSuggestionDiplomaticPassScenario(
        label: 'isIndependentDiplomaticCandidate flags economic and boycott types',
        target: OrderSuggestionDiplomaticPassTarget
            .isIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes,
      ),
      OrderSuggestionDiplomaticPassScenario(
        label: 'playerOverturesByTargetIdForPlayer keeps first row per target',
        target: OrderSuggestionDiplomaticPassTarget
            .playerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget,
      ),
      OrderSuggestionDiplomaticPassScenario(
        label: 'acceptDeclareWarCandidatesForTargets skips self and at-war targets',
        target: OrderSuggestionDiplomaticPassTarget
            .acceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets,
      ),
    ];
