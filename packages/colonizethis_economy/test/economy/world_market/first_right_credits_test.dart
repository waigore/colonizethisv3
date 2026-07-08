// Consolidated FRR credits runners (Refs #3939 phase 3 slice 2).
//
// Relation 75 / 100 / 0 credit-formula scenarios (rate + treasury), plus
// the "buyer == owning GP (D2 match) is excluded from D4" case, are pinned
// 1:1 by the issue-AC audit file
// `first_right_of_refusal_issue_acceptance_criteria_d5_test.dart`
// (groups AC #2, AC #3, AC #4) and are intentionally not duplicated here.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeFirstRightCredits (#2992 D4)', () {
    for (final scenario in frrCreditsDefensiveScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('computeFirstRightCredits aggregation (#3753 R8.2 full share)', () {
    for (final scenario in frrCreditsAggregationScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });

  group('computeFirstRightCredits embassy kickbacks (#3753 R8.3)', () {
    for (final scenario in frrCreditsKickbackScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });
}
