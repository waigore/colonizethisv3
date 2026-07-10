// Table-driven draft-work move exclusion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_move_excludes_unit_with_draft_work_run_rows.dart';

class OrderSuggestionMoveExcludesUnitWithDraftWorkScenario
    implements LabeledScenario {
  const OrderSuggestionMoveExcludesUnitWithDraftWorkScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionMoveExcludesUnitWithDraftWorkScenario(
  OrderSuggestionMoveExcludesUnitWithDraftWorkScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionMoveExcludesUnitWithDraftWorkScenario>
orderSuggestionMoveExcludesUnitWithDraftWorkScenarios() => const [
  OrderSuggestionMoveExcludesUnitWithDraftWorkScenario(
    label:
        'suggestMoveOrders emits no MoveOrder for a unit that already has a draft WorkOrder',
    run: osmeudwRunNoMoveWhenDraftWorkExists,
  ),
];
