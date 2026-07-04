// Table-driven unit tests for GpTreasuryCreditAccumulator (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('GpTreasuryCreditAccumulator<int>', () {
    for (final scenario in gpTreasuryCreditIntScenarios()) {
      test(scenario.label, () {
        runGpTreasuryCreditIntScenario(scenario);
      });
    }
  });

  group('GpTreasuryCreditAccumulator<double> (FRR zero-profit semantics)', () {
    for (final scenario in gpTreasuryCreditDoubleScenarios()) {
      test(scenario.label, () {
        runGpTreasuryCreditDoubleScenario(scenario);
      });
    }
  });
}
