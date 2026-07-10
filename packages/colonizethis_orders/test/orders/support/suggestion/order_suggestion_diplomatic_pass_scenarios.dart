// Table-driven diplomatic-pass suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_pass_run_rows.dart';

/// One row in diplomatic-pass suggestion scenario tables.
class OrderSuggestionDiplomaticPassScenario implements RefsScenario {
  const OrderSuggestionDiplomaticPassScenario({
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

void runOrderSuggestionDiplomaticPassScenario(
  OrderSuggestionDiplomaticPassScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDiplomaticPassScenario>
orderSuggestionDiplomaticPassScenarios() => const [
  OrderSuggestionDiplomaticPassScenario(
    label: 'isIndependentDiplomaticCandidate flags economic and boycott types',
    run: osdpRunIsIndependentDiplomaticCandidateFlagsEconomicAndBoycottTypes,
  ),
  OrderSuggestionDiplomaticPassScenario(
    label: 'playerOverturesByTargetIdForPlayer keeps first row per target',
    run: osdpRunPlayerOverturesByTargetIdForPlayerKeepsFirstRowPerTarget,
  ),
  OrderSuggestionDiplomaticPassScenario(
    label: 'acceptDeclareWarCandidatesForTargets skips self and at-war targets',
    run: osdpRunAcceptDeclareWarCandidatesForTargetsSkipsSelfAndAtWarTargets,
  ),
];
