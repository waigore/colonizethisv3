// Table-driven matrix consolidation of the EXPAND peace predicate / decider
// pins (Refs #3749 / #3941).
//
// Single contract file: scalar below-quota predicates, `(game, snapshot) -> bool`
// peace predicates, `(game, snapshot) -> List<String>` peace-target deciders,
// and `(game, snapshot) -> String?` sole-GP peace-target deciders. Case
// tables and fixture builders live in topical `expand_phase_peace_matrix_*_cases.dart`
// modules plus `expand_phase_peace_matrix_support.dart`.
//
// Coverage is preserved 1:1 from the four former matrix shards — every row
// keeps the same fixture and the verbatim regression `reason`.

import 'expand_phase_peace_matrix_scalar_predicate_cases.dart';
import 'expand_phase_peace_matrix_game_predicate_cases.dart';
import 'expand_phase_peace_matrix_target_decider_cases.dart';
import 'expand_phase_peace_matrix_sole_gp_cases.dart';

void main() {
  registerExpandPeaceScalarPredicateCases();
  registerExpandPeaceGamePredicateCases();
  registerExpandPeaceTargetDeciderCases();
  registerExpandPeaceSoleGpCases();
}
