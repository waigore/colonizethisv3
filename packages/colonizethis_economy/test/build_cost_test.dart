// Table-driven unit tests for build_cost (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('build_cost', () {
    for (final scenario in buildCostScenarios()) {
      test(scenario.label, () {
        runBuildCostScenario(scenario);
      });
    }
  });
}
