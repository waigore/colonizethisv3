import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('addUnits', () {
    for (final scenario in addUnitsScenarios()) {
      test(scenario.label, () {
        runCommodityTotalsScenario(scenario);
      });
    }
  });

  group('sumValues', () {
    for (final scenario in sumValuesScenarios()) {
      test(scenario.label, () {
        runCommodityTotalsScenario(scenario);
      });
    }
  });

  group('sumNestedValues', () {
    for (final scenario in sumNestedValuesScenarios()) {
      test(scenario.label, () {
        runCommodityTotalsScenario(scenario);
      });
    }
  });
}
