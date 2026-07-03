import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeFirstRightCredits aggregation (#3753 R8.2 full share)', () {
    for (final scenario in frrCreditsAggregationScenarios()) {
      test(scenario.label, () => runFrrCreditsScenario(scenario));
    }
  });
}
