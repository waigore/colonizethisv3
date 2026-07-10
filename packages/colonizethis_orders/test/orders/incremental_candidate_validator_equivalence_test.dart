// Consolidated IncrementalCandidateValidator equivalence runners (Refs #3949).

import 'package:colonizethis_test/test.dart';

import 'support/incremental/incremental_candidate_validator_equivalence_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  suppressLogsForTests();

  group('IncrementalCandidateValidator equivalence (Refs #2237)', () {
    runLabeledScenarios(
      incrementalCandidateValidatorEquivalenceScenarios(),
      runRunnableScenario,
    );
  });
}
