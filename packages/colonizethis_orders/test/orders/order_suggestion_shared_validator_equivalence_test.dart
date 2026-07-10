// Consolidated shared-validator equivalence runner (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_shared_validator_equivalence_scenarios.dart';

/// Equivalence coverage for the optional `sharedCandidateValidator` parameter
/// on top-level suggest functions (Refs #2394,
/// SPEC/program/order-suggestions.md § Throughput bounds).
///
/// Negative coverage (mismatched playerId assertions) lives in
/// `order_suggestion_shared_validator_negative_test.dart`.
void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'shared validator equivalence (Refs #2394)',
    orderSuggestionSharedValidatorEquivalenceScenarios(),
    runOrderSuggestionSharedValidatorEquivalenceScenario,
  );
}
