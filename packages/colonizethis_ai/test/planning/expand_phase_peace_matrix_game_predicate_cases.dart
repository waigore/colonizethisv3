// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'expand_phase_peace_matrix_game_predicate_truth_cases.dart';
import 'expand_phase_peace_matrix_game_predicate_determinism_cases.dart';

void registerExpandPeaceGamePredicateCases() {
  registerExpandPeaceGamePredicateTruthCases();
  registerExpandPeaceGamePredicateDeterminismCases();
}
