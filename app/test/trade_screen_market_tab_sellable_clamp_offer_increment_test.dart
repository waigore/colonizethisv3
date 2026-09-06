// Trade Market sellable-clamp increment / bid-headroom controls (Refs #4734 Slice G).
// Offer chip clamp: trade_screen_market_tab_sellable_clamp_offer_controls_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_sellable_clamp_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'TradeScreen Market tab sellable clamp increment (Refs #4734 Slice G)',
    () {
      testWidgets(
        'incrementing a saturated Offer row is a silent no-op (the staged '
        'quantity stays at the cap and the headroom stays at (0))',
        (tester) async {
          final ProviderContainer container =
              await pumpTradeScreenWithContainer(
                tester,
                game: buildTradeTestGame(
                  stockpile: const <CommodityId, int>{'timber': 5},
                ),
                initialOrders: sellableClampTradeOrders(
                  sellableClampTimberTrade(quantity: 5),
                ),
              );

          await tapSellableClampKey(
            tester,
            TradeScreenMarketKeys.marketRowIncrementKey(kSellableClampTimber),
          );

          expect(
            stagedSellableClampOrder(container, kSellableClampTimber)?.quantity,
            5,
          );
          expectSellableClampReadout(tester, kSellableClampTimber, '(0)');
        },
      );

      testWidgets(
        'incrementing an Offer row with headroom > 0 raises the staged '
        'quantity by 1 and the headroom display decreases accordingly',
        (tester) async {
          final ProviderContainer container =
              await pumpTradeScreenWithContainer(
                tester,
                game: buildTradeTestGame(
                  stockpile: const <CommodityId, int>{'timber': 7},
                ),
                initialOrders: sellableClampTradeOrders(
                  sellableClampTimberTrade(quantity: 2),
                ),
              );

          expectSellableClampReadout(tester, kSellableClampTimber, '(5)');

          await tapSellableClampKey(
            tester,
            TradeScreenMarketKeys.marketRowIncrementKey(kSellableClampTimber),
          );
          expect(
            stagedSellableClampOrder(container, kSellableClampTimber)?.quantity,
            3,
          );
          expectSellableClampReadout(tester, kSellableClampTimber, '(4)');
        },
      );

      testWidgets('bids do not consume the offer headroom (bid row\'s `(N)` is '
          'unaffected by the staged bid quantity)', (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            stockpile: const <CommodityId, int>{'timber': 10},
          ),
          initialOrders: sellableClampTradeOrders(
            sellableClampTimberTrade(type: TradeOrderType.bid, quantity: 4),
          ),
        );

        expectSellableClampReadout(
          tester,
          kSellableClampTimber,
          '(10)',
          reason:
              'Refs #3093 — bids do not reserve stockpile (per '
              'SPEC/game/world-market.md § Cargo). The offer headroom '
              'is independent of staged bids.',
        );
      });
    },
  );
}
