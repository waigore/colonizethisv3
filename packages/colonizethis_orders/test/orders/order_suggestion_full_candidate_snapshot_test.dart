// Consolidated full-candidate snapshot runner (Refs #3949 wave 3 slice 96).

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_full_candidate_snapshot_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarios(
    orderSuggestionFullCandidateSnapshotScenarios(),
    runOrderSuggestionFullCandidateSnapshotScenario,
  );
}
