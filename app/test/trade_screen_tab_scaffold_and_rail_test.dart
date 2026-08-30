// Widget tests for the TradeScreen scaffold slices
// (Refs #2993 E1+E2+E3 chrome + E4 two-tab body). SPEC/ui/trade-screen.md.

import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/widgets/panels/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'panel_test_fixtures.dart';
import 'trade_screen_scaffold_test_support.dart';
import 'widget_test_pumps.dart';

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

    Hive.init('./.dart_tool/test_hive_trade_screen_tabs_and_rail');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget tradeHost({bool globalObserve = false}) => buildTradeRouteHost(
    game: game,
    humanPlayer: humanPlayer,
    gamesBox: gamesBox,
    globalObserve: globalObserve,
  );

  Widget railHost() => buildTradeLeftRailHost(
    game: game,
    humanPlayer: humanPlayer,
    gamesBox: gamesBox,
  );

  group('TradeScreen tab scaffold slice (Refs #2993 E4)', () {
    testWidgets(
      'tabs body hosts a CtTabStrip with literal Market + Deal Book labels in order',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost());

        expect(find.byKey(TradeScreenMarketKeys.tabsBodyKey), findsOneWidget);

        final stripFinder = find.descendant(
          of: find.byKey(TradeScreenMarketKeys.tabsBodyKey),
          matching: find.byType(CtTabStrip),
        );
        expect(stripFinder, findsOneWidget);

        final CtTabStrip strip = tester.widget<CtTabStrip>(stripFinder);
        expect(strip.tabLabels, <String>[
          TradeScreenMarketKeys.marketTabLabel,
          TradeScreenDealBookKeys.dealBookTabLabel,
        ]);
        expect(strip.tabViews.length, 2);
      },
    );

    testWidgets(
      'both Market and Deal Book tab body keys are mounted (IndexedStack '
      'keeps non-selected tab in tree, off-stage)',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost());

        // Default selection foregrounds the Market tab; that body is on
        // stage and resolves under default `skipOffstage: true`.
        expect(
          find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
          findsOneWidget,
        );

        // Non-selected Deal Book tab is wrapped in Visibility(visible:
        // false) by IndexedStack and reads as off-stage to default
        // finders. Asserting `skipOffstage: false` confirms the widget
        // is still in the tree (state is preserved) — the contract that
        // lets E5/E6 swap each tab body in place without remounting the
        // tab strip.
        expect(
          find.byKey(
            TradeScreenDealBookKeys.dealBookTabBodyKey,
            skipOffstage: false,
          ),
          findsOneWidget,
          reason:
              'IndexedStack mounts both tab bodies; the non-selected '
              'Deal Book body must remain in the element tree so E6 can '
              'replace it in place.',
        );
        // Conversely the off-stage Deal Book body must not be reachable
        // from default (skipOffstage: true) finders — that is the
        // visible/foregrounded contract for the default Market tab.
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
          findsNothing,
        );
      },
    );

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

  group('GameMapEmpireLeftRail Trade button (Refs #2993 E3)', () {
    testWidgets('rail exposes kEmpireTradeButtonKey between Production and '
        'Development', (tester) async {
      await tester.pumpWidget(railHost());
      await pumpSettleCapped(tester);

      final trade = find.byKey(kEmpireTradeButtonKey);
      expect(trade, findsOneWidget);

      final productionTopLeft = tester.getTopLeft(
        find.byKey(kEmpireProductionButtonKey),
      );
      final tradeTopLeft = tester.getTopLeft(trade);
      final developmentTopLeft = tester.getTopLeft(
        find.byKey(kEmpireDevelopmentButtonKey),
      );

      // Vertical stack ordering: Production -> Trade -> Development.
      expect(
        tradeTopLeft.dy,
        greaterThan(productionTopLeft.dy),
        reason: 'Trade button sits below Production per SPEC #2993 R4.',
      );
      expect(
        developmentTopLeft.dy,
        greaterThan(tradeTopLeft.dy),
        reason: 'Development sits below Trade per SPEC #4175.',
      );
    });

    testWidgets('tapping Trade navigates to TradeScreen via Routes.generate', (
      tester,
    ) async {
      await tester.pumpWidget(railHost());
      await pumpSettleCapped(tester);

      await tester.tap(find.byKey(kEmpireTradeButtonKey));
      await pumpSettleCapped(tester);

      expect(find.byType(TradeScreen), findsOneWidget);
      expect(find.byKey(TradeScreenMarketKeys.topBarKey), findsOneWidget);
    });
  });
}
