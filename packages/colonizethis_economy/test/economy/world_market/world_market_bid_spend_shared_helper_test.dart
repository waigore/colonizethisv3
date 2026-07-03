// Parity tests for the shared bid-spend summation helper (Refs #3427, #3856).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('shared bid-spend helper parity (Refs #3427)', () {
    for (final scenario in bidSpendParityScenarios()) {
      test(scenario.label, () => scenario.run(rules));
    }
  });
}
