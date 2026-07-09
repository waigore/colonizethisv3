// Consolidated draft-work move exclusion runner (Refs #3949 wave 3 slice 96).
//
// Refs #2082 regression: Full AI applies work before move planning; move
// suggestions must not include the same civilian unitId as an existing draft
// WorkOrder (move/work XOR via order engine validation).

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_move_excludes_unit_with_draft_work_scenarios.dart';

void main() {
  runLabeledScenarios(
    orderSuggestionMoveExcludesUnitWithDraftWorkScenarios(),
    runOrderSuggestionMoveExcludesUnitWithDraftWorkScenario,
  );
}
