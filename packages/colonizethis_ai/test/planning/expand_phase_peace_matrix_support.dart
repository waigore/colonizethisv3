// Shared scaffolding for the table-driven consolidation of the four EXPAND
// peace matrix contract suites (Refs #3749 / #3941).
//
// Case tables live in sibling `expand_phase_peace_matrix_*_cases.dart` modules
// so the single contract file `expand_phase_peace_matrix_test.dart` stays
// under the non-comment line gate. Former shards:
//
//   - `expand_phase_planner_below_quota_peace_predicate_matrix_test.dart`
//   - `expand_phase_planner_peace_predicate_game_matrix_test.dart`
//   - `expand_phase_planner_peace_target_decider_matrix_test.dart`
//   - `expand_phase_planner_sole_gp_peace_target_matrix_test.dart`
//
// Each module preserves 1:1 row coverage from its legacy shard; this library
// documents the contract shape for future shared fixture extraction.
