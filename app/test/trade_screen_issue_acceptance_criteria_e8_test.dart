// Issue-AC-mapped widget tests for `TradeScreen` (`#2993` E8).
// SPEC/ui/trade-screen.md.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_e8_test_helpers.dart';
import 'trade_screen_e8_market_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() => tradeE8InitRouteHostHive(suiteId: 'trade_screen_e8'));

  group('AC #1 — Left rail Trade icon opens TradeScreen full-screen dark '
      'editorial-monocle surface (#2993 E8 (a))', () {
    testWidgets(
      'tapping kEmpireTradeButtonKey pushes TradeScreen with the dark '
      'CtTopBar (Trade title, Map back affordance, 18 px trade icon) '
      'and the two-tab Market + Deal Book body',
      (tester) async {
        await tester.pumpWidget(tradeE8LeftRailHost());
        await pumpSettleCapped(tester);

        final trade = find.byKey(kEmpireTradeButtonKey);
        expect(trade, findsOneWidget);
        final productionY = tester
            .getTopLeft(find.byKey(kEmpireProductionButtonKey))
            .dy;
        final tradeY = tester.getTopLeft(trade).dy;
        final civilianY = tester
            .getTopLeft(find.byKey(kEmpireCivilianUnitsButtonKey))
            .dy;
        expect(tradeY, greaterThan(productionY));
        expect(civilianY, greaterThan(tradeY));

        await tester.tap(trade);
        await pumpSettleCapped(tester);

        expect(find.byType(TradeScreen), findsOneWidget);
        expect(find.byType(AppBar), findsNothing);
        expectTradeE8Chrome(tester);
      },
    );

    testWidgets(
      'CtTopBar back affordance returns to the host route (TradeScreen '
      'is dismissed) — confirms the full-screen feature contract pops '
      'cleanly without leaking chrome',
      (tester) async {
        await tradeE8OpenTradeFromRouteHost(tester);
        expect(find.byType(TradeScreen), findsOneWidget);

        final back = find.descendant(
          of: find.byType(CtTopBar),
          matching: find.byType(CtBackButton),
        );
        expect(back, findsOneWidget);
        await tester.tap(back);
        await pumpSettleCapped(tester);
        expect(find.byType(TradeScreen), findsNothing);
      },
    );
  });

  group('AC #2 / #3 — stage bid+qty, offer default, mutual exclusion '
      '(#2993 E8 (b)(c))', () {
    testWidgets('bid timber to qty 5; offer fabric defaults to qty 1', (
      tester,
    ) async {
      final ProviderContainer container = await tradeE8PumpMarket(tester);
      expect(tradeE8StagedOrder(container, kTradeE8Timber), isNull);

      await tradeE8TapBid(tester, kTradeE8Timber);
      await tradeE8IncrementCommodity(tester, kTradeE8Timber, 4);
      final TradeOrder? bid = tradeE8StagedOrder(container, kTradeE8Timber);
      expect(bid, isNotNull);
      expect(bid!.commodityId, kTradeE8Timber);
      expect(bid.type, TradeOrderType.bid);
      expect(bid.quantity, 5);
      expect(bid.priority, TradeScreenMarketKeys.marketRowDefaultPriority);
      expect(tradeE8StagedRowCountForPlayer(container), 1);

      await tradeE8TapOffer(tester, kTradeE8Fabric);
      final TradeOrder? offer = tradeE8StagedOrder(container, kTradeE8Fabric);
      expect(offer?.type, TradeOrderType.offer);
      expect(offer?.quantity, TradeScreenMarketKeys.marketRowQuantityDefault);
      expect(offer?.priority, TradeScreenMarketKeys.marketRowDefaultPriority);
    });

    testWidgets(
      'per-commodity mutual exclusion + cross-commodity coexistence',
      (tester) async {
        final ProviderContainer container = await tradeE8PumpMarket(tester);

        await tradeE8TapBid(tester, kTradeE8Timber);
        await tradeE8IncrementCommodity(tester, kTradeE8Timber, 2);
        expect(
          tradeE8StagedOrder(container, kTradeE8Timber)?.type,
          TradeOrderType.bid,
        );
        expect(tradeE8StagedOrder(container, kTradeE8Timber)?.quantity, 3);

        await tradeE8TapOffer(tester, kTradeE8Timber);
        final TradeOrder? flipped = tradeE8StagedOrder(
          container,
          kTradeE8Timber,
        );
        expect(flipped?.type, TradeOrderType.offer);
        expect(flipped?.quantity, 3);
        expect(
          container
              .read(currentOrdersProvider)
              .tradeOrdersByPlayerId[kTradeE8HumanPlayerId]!
              .where((TradeOrder o) => o.commodityId == kTradeE8Timber)
              .length,
          1,
        );

        await tradeE8TapBid(tester, kTradeE8Timber);
        await tradeE8TapOffer(tester, kTradeE8Fabric);
        expect(
          tradeE8StagedOrder(container, kTradeE8Timber)?.type,
          TradeOrderType.bid,
        );
        expect(
          tradeE8StagedOrder(container, kTradeE8Fabric)?.type,
          TradeOrderType.offer,
        );
        expect(tradeE8StagedRowCountForPlayer(container), 2);
      },
    );
  });

  group(
    'AC #4 — Deal Book renders previous-turn filled + carry-forward rows '
    'with correct quantities, prices, and treasury totals (#2993 E8 (d))',
    () {
      testWidgets('Given a partial timber bid (filled 5 of 10 at price 8.4, '
          'displayed as floor=8) plus a carry-forward fabric offer of qty '
          '3 (no fills), when the player opens the Deal Book tab, then '
          'the bids panel shows the timber filled row + timber '
          'carry-forward row + total spent of 40 (= 5 × floor(8.4)), and '
          'the offers panel shows the fabric carry-forward row with total '
          'received of 0', (tester) async {
        await tradeE8PumpMarket(
          tester,
          worldMarketState: tradeE8PartialTimberDealBookMarket(),
        );
        await tradeE8SwitchToDealBook(tester);
        for (final finder in <Finder>[
          find.byKey(
            TradeScreenDealBookKeys.dealBookFilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          find.text('Timber — 5 at £8 = £40'),
          find.byKey(
            TradeScreenDealBookKeys.dealBookUnfilledRowKey(
              TradeScreenDealBookKeys.dealBookSideBids,
              0,
            ),
          ),
          find.text('Timber — 5'),
          find.byKey(
            TradeScreenDealBookKeys.dealBookUnfilledRowKey(
              TradeScreenDealBookKeys.dealBookSideOffers,
              0,
            ),
          ),
          find.text('Fabric — 3'),
        ]) {
          expect(finder, findsOneWidget);
        }
        expectTradeE8DealBookTotals(
          tester,
          bidsTotal: TradeScreenDealBookKeys.formatTotalsLine(
            TradeScreenDealBookKeys.dealBookTotalSpentLabel,
            40,
          ),
          offersTotal: TradeScreenDealBookKeys.formatTotalsLine(
            TradeScreenDealBookKeys.dealBookTotalReceivedLabel,
            0,
          ),
        );
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookFilledRowKey(
              TradeScreenDealBookKeys.dealBookSideOffers,
              0,
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookBidsEmptyKey),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersEmptyKey),
          findsNothing,
        );
      });
    },
  );
}
