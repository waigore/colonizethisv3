// Widget tests for the Trade Market tab treasury bid cap (Refs #3093 —
// SPEC/ui/trade-screen.md § Market tab; SPEC/game/world-market.md).
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_treasury_bid_cap_pending_support.dart';
import 'trade_screen_market_tab_treasury_bid_cap_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab treasury bid cap (Refs #3093)', () {
    testWidgets(
      'treasury 100, timber price 30, no staged orders → tapping Bid stages '
      'a TradeOrder with quantity 1 (default fits inside the budget of 3)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30},
          ),
        );

        await tapTreasuryMarketBid(tester, kTreasuryBidTimber);

        final TradeOrder? staged = stagedTreasuryBidOrder(
          container,
          kTreasuryBidTimber,
        );
        expect(staged, isNotNull);
        expect(staged!.type, TradeOrderType.bid);
        expect(
          staged.quantity,
          TradeScreenMarketKeys.marketRowQuantityDefault,
          reason:
              'Treasury 100 / price 30 = 3 units of headroom; default '
              'staged qty 1 fits inside the budget.',
        );
      },
    );

    testWidgets('treasury 100, timber price 30, staged Bid timber qty 3 → '
        'incrementing further is a silent no-op (budget saturated)', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          treasury: 100,
          prices: const {kTreasuryBidTimber: 30},
        ),
        initialOrders: stagedTreasuryTradeOrders(
          commodityId: kTreasuryBidTimber,
          type: TradeOrderType.bid,
          quantity: 3,
        ),
      );

      await tapTreasuryMarketIncrement(tester, kTreasuryBidTimber);

      final TradeOrder? staged = stagedTreasuryBidOrder(
        container,
        kTreasuryBidTimber,
      );
      expect(
        staged?.quantity,
        3,
        reason:
            'Refs #3093 — total spend 4×30=120 exceeds treasury 100, so '
            'the `+` tap is a silent no-op.',
      );
    });

    testWidgets(
      'treasury 100, staged Bid timber qty 3 (spend 90), iron price 80 → '
      'tapping the Bid chip on a fresh iron row is a silent no-op '
      '(headroom 10 < rowPrice 80)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30, kTreasuryBidIron: 80},
          ),
          initialOrders: stagedTreasuryTradeOrders(
            commodityId: kTreasuryBidTimber,
            type: TradeOrderType.bid,
            quantity: 3,
          ),
        );

        await tapTreasuryMarketBid(tester, kTreasuryBidIron);

        expect(
          stagedTreasuryBidOrder(container, kTreasuryBidIron),
          isNull,
          reason:
              'Refs #3093 — treasury headroom 10 cannot cover iron price 80; '
              'toggle must be a silent no-op.',
        );
        expect(
          stagedTreasuryBidOrder(container, kTreasuryBidTimber)?.quantity,
          3,
        );
      },
    );

    testWidgets('treasury 50, timber price 30, staged Offer timber qty 4 → '
        'tapping Bid clamps the staged bid quantity to treasury budget '
        '(min(4, 50 / 30) = min(4, 1) = 1)', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          treasury: 50,
          prices: const {kTreasuryBidTimber: 30},
          stockpile: const {kTreasuryBidTimber: 10},
        ),
        initialOrders: stagedTreasuryTradeOrders(
          commodityId: kTreasuryBidTimber,
          type: TradeOrderType.offer,
          quantity: 4,
        ),
      );

      await tapTreasuryMarketBid(tester, kTreasuryBidTimber);

      final TradeOrder? staged = stagedTreasuryBidOrder(
        container,
        kTreasuryBidTimber,
      );
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.bid);
      expect(
        staged.quantity,
        1,
        reason:
            'Refs #3093 — prior offer qty 4 is clamped down to treasury '
            'budget 50 / 30 = 1 when toggling Offer → Bid.',
      );
    });

    testWidgets(
      'treasury 100, price map omits commodity and catalog default is also '
      'null (manufactured `lumber`) → Bid toggle stages a TradeOrder under '
      'the cargo cap only (treasury clamp skipped)',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const <CommodityId, int>{},
          ),
        );

        await tapTreasuryMarketBid(tester, kTreasuryBidLumber);

        final TradeOrder? staged = stagedTreasuryBidOrder(
          container,
          kTreasuryBidLumber,
        );
        expect(
          staged,
          isNotNull,
          reason:
              'Refs #3093 — when rowPrice is null (manufactured commodity, '
              'no catalog default), the treasury clamp is skipped so the '
              'cargo cap is the only constraint on the bid toggle; the '
              'validator-side enforcement (follow-up) covers spend cases '
              'for unpriced commodities.',
        );
        expect(staged!.type, TradeOrderType.bid);
        expect(staged.quantity, TradeScreenMarketKeys.marketRowQuantityDefault);
      },
    );

    testWidgets('treasury 100, timber price 30, staged Bid timber qty 2 → '
        'decrementing the staged bid still works (decrement is not gated by '
        'the treasury cap)', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          treasury: 100,
          prices: const {kTreasuryBidTimber: 30},
        ),
        initialOrders: stagedTreasuryTradeOrders(
          commodityId: kTreasuryBidTimber,
          type: TradeOrderType.bid,
          quantity: 2,
        ),
      );

      await tapTreasuryMarketDecrement(tester, kTreasuryBidTimber);

      expect(
        stagedTreasuryBidOrder(container, kTreasuryBidTimber)?.quantity,
        1,
      );
    });

    registerTreasuryBidCapPendingTests();
  });
}
