// Table-driven unit tests for capBidQuantityForBudgets (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('capBidQuantityForBudgets (Refs #3836)', () {
    for (final scenario in capBidQuantityForBudgetsScenarios) {
      test(scenario.label, () {
        expect(
          capBidQuantityForBudgets(
            bidQuantity: scenario.bidQuantity,
            remainingCargoBudget: scenario.remainingCargoBudget,
            remainingTreasuryBudget: scenario.remainingTreasuryBudget,
            unitPrice: scenario.unitPrice,
          ),
          scenario.expected,
        );
      });
    }
  });
}
