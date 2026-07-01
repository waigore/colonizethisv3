// Unit tests for `effectiveMarketPriceForCommodityId` (Refs #3093).
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

  group('effectiveMarketPriceForCommodityId (Refs #3093)', () {
    test(
      'returns the integer price from worldMarketState.prices when present',
      () {
        final game = buildTreasuryBidBudgetGame(prices: const {'timber': 42});
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: 'timber',
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          42,
        );
      },
    );

    test(
      'falls back to ResourceRules.defaultMarketPriceForCommodityId when the '
      'prices map omits the commodity',
      () {
        final game = buildTreasuryBidBudgetGame(
          prices: const <CommodityId, int>{},
        );
        final int? defaultTimber = rules.defaultMarketPriceForCommodityId(
          'timber',
        );
        expect(defaultTimber, isNotNull);
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: 'timber',
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          defaultTimber,
        );
      },
    );

    test(
      'falls back to the catalog manufactured base price when the '
      'prices map omits the commodity (Refs #3093 manufactured-default-prices)',
      () {
        final game = buildTreasuryBidBudgetGame(
          prices: const <CommodityId, int>{},
        );
        final int? defaultLumber = rules.defaultMarketPriceForCommodityId(
          'lumber',
        );
        expect(
          defaultLumber,
          isNotNull,
          reason:
              'Manufactured commodities now have catalog defaults per '
              'SPEC/game/commodity-catalog.md § Manufactured base prices.',
        );
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: 'lumber',
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          defaultLumber,
        );
      },
    );

    test('returns null only when neither prices nor catalog has a value '
        '(defensive fallback for unknown / future commodity ids)', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const <CommodityId, int>{},
      );
      expect(rules.defaultMarketPriceForCommodityId('not_a_commodity'), isNull);
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'not_a_commodity',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
      );
    });

    test('returns null for riches commodities regardless of stored prices', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const {'gold': 1000, 'silver': 500, 'gems': 999},
      );
      expect(
        effectiveMarketPriceForCommodityId(
          commodityId: 'gold',
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        isNull,
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

    test(
      'treats negative stored prices as missing and falls back to catalog',
      () {
        final game = buildTreasuryBidBudgetGame(prices: const {'timber': -5});
        final int? defaultTimber = rules.defaultMarketPriceForCommodityId(
          'timber',
        );
        expect(defaultTimber, isNotNull);
        expect(
          effectiveMarketPriceForCommodityId(
            commodityId: 'timber',
            worldMarket: game.worldMarketState,
            resourceRules: rules,
          ),
          defaultTimber,
        );
      },
    );
  });
}
