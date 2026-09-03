import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'panel_test_fixtures.dart';
import 'trade_screen_scaffold_test_support.dart';
import 'widget_test_pumps.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Lightweight fixture (Refs #3656): the trade route host, left rail, and
    // TradeScreen body read only `game.players` (for the supplied player), the
    // static CommodityCatalog, and a default-empty WorldMarketState — no
    // generated map/topology data — so the ~7-11s procedural map generator is
    // avoided.
    game = buildTradePanelTestGame();
    humanPlayer = game.players.firstWhere(
      (p) => p.isHuman,
      orElse: () => game.players.first,
    );

    gamesBox = await openAppTestHiveBox(
      suiteId: 'trade_screen_tab_scaffold_tabs',
    );
  });

  Widget tradeHost({bool globalObserve = false}) => buildTradeRouteHost(
    game: game,
    humanPlayer: humanPlayer,
    gamesBox: gamesBox,
    globalObserve: globalObserve,
  );

  group('TradeScreen tab scaffold slice (Refs #2993 E4)', () {
    testWidgets(
      'tapping the Deal Book label switches the foregrounded IndexedStack '
      'child to the Deal Book tab body',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost());

        // Locate the IndexedStack created by CtTabStrip; verify default
        // selection is index 0 (Market).
        final stackFinder = find.descendant(
          of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
          matching: find.byType(IndexedStack),
        );
        expect(stackFinder, findsOneWidget);
        IndexedStack stack = tester.widget<IndexedStack>(stackFinder);
        expect(
          stack.index,
          0,
          reason:
              'SPEC/ui/trade-screen.md § Acceptance criteria — Tab '
              'scaffold slice: default selection is the Market tab '
              '(index 0).',
        );

        // Tap the `Deal Book` label inside the tab strip.
        final dealBookLabel = find.descendant(
          of: find.byType(CtTabStrip),
          matching: find.text(TradeScreenDealBookKeys.dealBookTabLabel),
        );
        expect(dealBookLabel, findsOneWidget);
        await tester.tap(dealBookLabel);
        await pumpSettleCapped(tester);

        // After the tap the IndexedStack should foreground the Deal Book
        // tab body (index 1).
        stack = tester.widget<IndexedStack>(stackFinder);
        expect(
          stack.index,
          1,
          reason:
              'SPEC/ui/trade-screen.md § Acceptance criteria — tapping '
              '`Deal Book` foregrounds the Deal Book tab body keyed '
              'tradeScreenDealBookTabBody.',
        );
      },
    );

    testWidgets(
      'Deal Book tab body mounts the live ledger content (Refs #2993 E6) '
      'after the user taps the Deal Book label',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost());

        // Tap the Deal Book tab label to swap the on-stage child.
        final dealBookLabel = find.descendant(
          of: find.byType(CtTabStrip),
          matching: find.text(TradeScreenDealBookKeys.dealBookTabLabel),
        );
        expect(dealBookLabel, findsOneWidget);
        await tester.tap(dealBookLabel);
        await pumpSettleCapped(tester);

        // After tap, the Deal Book tab body is on stage and renders the
        // live ledger content root keyed `tradeScreenDealBookContent`
        // (Refs #2993 E6) under the same `tradeScreenDealBookTabBody`
        // body root — the tab-body key remained stable so existing
        // tab-switch tests continue to pin the same affordance.
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
            matching: find.byKey(TradeScreenDealBookKeys.dealBookContentKey),
          ),
          findsOneWidget,
        );
        // Both bids and offers panel containers are always present in
        // the live content; their per-row contents are exercised by the
        // dedicated E6 panel tests in trade_screen_deal_book_tab_e6_test.dart.
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookBidsPanelKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersPanelKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookBidsTotalsKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookOffersTotalsKey),
          findsOneWidget,
        );
      },
    );
  });
}
