import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_treasury_bid_cap_support.dart';
import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();
  group('TradeScreen Market tab bid-budget header (Refs #4186)', () {
    testWidgets(
      'treasury 100, no staged bids → indicator reads Bid budget: 100 of 100',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30},
          ),
        );
        expect(bidBudgetIndicatorText(tester), 'Bid budget: 100 of 100');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsNothing,
        );
      },
    );
    testWidgets(
      'treasury 100, staged Bid timber qty 3 (spend 90) → indicator reads '
      'Bid budget: 10 of 100',
      (tester) async {
        await pumpTradeScreenWithContainer(
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
        expect(bidBudgetIndicatorText(tester), 'Bid budget: 10 of 100');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsNothing,
        );
      },
    );
    testWidgets(
      'treasury 90, staged Bid timber qty 3 (spend 90) → R == 0 shows warning',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 90,
            prices: const {kTreasuryBidTimber: 30},
          ),
          initialOrders: stagedTreasuryTradeOrders(
            commodityId: kTreasuryBidTimber,
            type: TradeOrderType.bid,
            quantity: 3,
          ),
        );
        expect(bidBudgetIndicatorText(tester), 'Bid budget: 0 of 90');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsOneWidget,
        );
        expect(
          find.text(TradeScreenMarketKeys.bidBudgetLimitWarningText),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'treasury 50, non-bid pending cost 60 → budget 0 with no bids shows '
      'warning (B == 0, S == 0)',
      (tester) async {
        final Game game = buildTradeTestGame(
          treasury: 50,
          prices: const {kTreasuryBidTimber: 30},
        );
        await pumpTradeScreenWithContainer(
          tester,
          game: game,
          extraOverrides: <Override>[treasuryBidSummaryOverride(game, -60)],
        );
        expect(bidBudgetIndicatorText(tester), 'Bid budget: 0 of 0');
        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetWarningKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'treasury 100, non-bid pending cost 40 → header budget reads 60 of 60 '
      'with no staged bids',
      (tester) async {
        final Game game = buildTradeTestGame(
          treasury: 100,
          prices: const {kTreasuryBidTimber: 30},
        );
        await pumpTradeScreenWithContainer(
          tester,
          game: game,
          extraOverrides: <Override>[treasuryBidSummaryOverride(game, -40)],
        );

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 60 of 60');
      },
    );

    testWidgets(
      'staged Offer timber qty 4 only → bid spend 0 and remaining equals full '
      'budget',
      (tester) async {
        await pumpTradeScreenWithContainer(
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

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 50 of 50');
      },
    );

    testWidgets(
      'incrementing staged bid updates the bid-budget line live',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30},
          ),
          initialOrders: stagedTreasuryTradeOrders(
            commodityId: kTreasuryBidTimber,
            type: TradeOrderType.bid,
            quantity: 1,
          ),
        );

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 70 of 100');

        await tapTreasuryMarketIncrement(tester, kTreasuryBidTimber);

        expect(bidBudgetIndicatorText(tester), 'Bid budget: 40 of 100');
      },
    );

    testWidgets(
      'bid-budget inline help tooltip mounts beside budget line',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            treasury: 100,
            prices: const {kTreasuryBidTimber: 30},
          ),
        );

        expect(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetTooltipKey),
          findsOneWidget,
        );
        expect(find.text('Why this limit?'), findsNothing);

        final CtIconAction budgetHelp = tester.widget<CtIconAction>(
          find.byKey(TradeScreenMarketKeys.marketBidBudgetTooltipKey),
        );
        expect(
          budgetHelp.tooltip,
          TradeScreenMarketKeys.bidBudgetLimitTooltipCopy,
        );
      },
    );

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
