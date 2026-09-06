// Trade Market bid-type cap tooltips and observe mode (Refs #4734 Slice G).
// Primary cap tests: trade_screen_market_tab_bid_type_cap_test.dart.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_bid_type_cap_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab bid-type cap chrome (Refs #4734 Slice G)', () {
    testWidgets(
      'inline help tooltips mount beside each limit line',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(),
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidGoodsTooltipKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketCargoTooltipKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetTooltipKey),
          findsOneWidget,
        );
        expect(find.text('Why this limit?'), findsNothing);

        final CtIconAction bidGoodsHelp = tester.widget<CtIconAction>(
          find.byKey(TradeScreenMarketKeys.marketBidGoodsTooltipKey),
        );
        expect(
          bidGoodsHelp.tooltip,
          TradeScreenMarketKeys.bidTypeLimitTooltipCopyCap3,
        );
      },
    );

    testWidgets(
      'observe mode → bid-goods indicator live; bid chip taps do not mutate',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(prices: const {kBidTypeCapTimber: 30}),
          canMutateViaUi: false,
        );

        expect(bidTypeCapIndicatorText(tester), 'Bid goods: 0 of 3');

        await tester.tap(bidTypeCapBidChip(kBidTypeCapTimber));
        await tester.pump();

        expect(bidTypeCapStagedOrder(container, kBidTypeCapTimber), isNull);
      },
    );
  });
}
