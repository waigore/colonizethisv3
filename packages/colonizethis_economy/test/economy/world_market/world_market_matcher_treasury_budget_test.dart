// Table-driven unit tests for matcher treasury budget helpers (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('maxAffordableBidQuantity (Refs #3856)', () {
    for (final scenario in maxAffordableBidQuantityScenarios) {
      test(scenario.label, () {
        expect(
          maxAffordableBidQuantity(
            bidRemaining: scenario.bidRemaining,
            pricePerUnit: scenario.pricePerUnit,
            remainingTreasuryBudget: scenario.remainingTreasuryBudget,
          ),
          scenario.expected,
        );
      });
    }
  });

  group('decrementTreasuryForFill (Refs #3856)', () {
    test('decrements running treasury tally after a priced fill', () {
      final remaining = <String, int>{'gp1': 100};
      decrementTreasuryForFill(
        buyerFactionId: 'gp1',
        matchQty: 3,
        pricePerUnit: 30.0,
        remainingTreasuryByBuyerFactionId: remaining,
      );
      expect(remaining['gp1'], 10);
    });

    test('skips decrement on missing-price free-fill path', () {
      final remaining = <String, int>{'gp1': 100};
      decrementTreasuryForFill(
        buyerFactionId: 'gp1',
        matchQty: 5,
        pricePerUnit: 0.0,
        remainingTreasuryByBuyerFactionId: remaining,
      );
      expect(remaining['gp1'], 100);
    });
  });
}
