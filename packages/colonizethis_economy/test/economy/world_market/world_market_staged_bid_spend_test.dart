// Table-driven unit tests for `stagedBidTotalSpendByPlayer` (Refs #3093).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('stagedBidTotalSpendByPlayer (Refs #3093)', () {
    for (final scenario in stagedBidSpendScenarios(rules)) {
      test(scenario.label, () {
        final game = buildTreasuryBidBudgetGame(prices: scenario.prices);
        final orders = scenario.orders.isEmpty
            ? const Orders()
            : humanOrdersWith(scenario.orders);
        expect(
          stagedBidTotalSpendByPlayer(
            orders: orders,
            playerId: scenario.playerId,
            game: game,
            resourceRules: rules,
          ),
          scenario.resolveExpectedSpend(rules),
          reason: scenario.label == 'ignores bids with non-positive quantity '
              '(defensive guard)'
              ? 'quantity == 0 should contribute nothing to the running total'
              : null,
        );
      });
    }
  });
}
