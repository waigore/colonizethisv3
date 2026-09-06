// Trade Market bid-budget header observe / saturation controls (Refs #4734 Slice G).
// Primary budget header tests: trade_screen_market_tab_bid_budget_header_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_treasury_bid_cap_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-budget edge cases (Refs #4734 Slice G)', () {
    testWidgets(
      'observe mode → bid-budget indicator remains live',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30},
          ),
          canMutateViaUi: false,
        );

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');

        await tapTreasuryMarketBid(tester, kTreasuryBidTimber);

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');
      },
    );

    testWidgets(
      'treasury-saturated increment remains silent no-op (clamp unchanged)',
      (tester) async {
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

        expect(
          stagedTreasuryBidOrder(container, kTreasuryBidTimber)?.quantity,
          3,
        );
        expect(bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
      },
    );

    testWidgets(
      'fresh iron bid refused when headroom below row price leaves indicator '
      'unchanged',
      (tester) async {
        await pumpTradeScreenWithContainer(
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

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');

        await tapTreasuryMarketBid(tester, kTreasuryBidIron);

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
      },
    );
  });
}
