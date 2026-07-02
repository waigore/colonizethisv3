// Table-driven unit tests for `effectiveMarketPriceForCommodityId` (Refs #3093).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('effectiveMarketPriceForCommodityId (Refs #3093)', () {
    for (final scenario in effectiveMarketPriceScenarios) {
      test(scenario.label, () {
        final game = buildTreasuryBidBudgetGame(prices: scenario.prices);
        final expected = expectedEffectiveMarketPrice(scenario, rules);
        if (scenario.useCatalogDefault) {
          expect(expected, isNotNull);
        }
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: scenario.commodityId,
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          expected,
        );
      });
    }

    test('returns null for silver riches regardless of stored prices', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const {'gold': 1000, 'silver': 500, 'gems': 999},
      );
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'silver',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
      );
    });
  });
}
