import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeFirstRightCredits (#2992 D4)', () {
    // Relation 75 / 100 / 0 credit-formula scenarios (rate + treasury), plus
    // the "buyer == owning GP (D2 match) is excluded from D4" case, are pinned
    // 1:1 by the issue-AC audit file
    // `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart`
    // (groups AC #2, AC #3, AC #4) and are intentionally not duplicated here.
    // This slice file retains only the defensive/skip branches the d5 contract
    // does not exercise.

    for (final scenario in frrCreditsDefensiveScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }

    // Multi-deal aggregation, multi-GP precedence, and determinism cases
    // live in `first_right_credits_aggregation_test.dart` to keep this
    // file under the `repo.logic_test_file_size` 400-line cap.
  });
}
