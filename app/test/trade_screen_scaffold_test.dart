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

    gamesBox = await openAppTestHiveBox(suiteId: 'trade_screen');
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

  group('TradeScreen scaffold slice (Refs #2993 E1+E2+E3)', () {
    test('UiScreenIds.tradeScreen is the stable GAME60001 id', () {
      // Regression guard: the stable ID is the contract surface that ties
      // SPEC/ui/screen-registry.md and SPEC/ui/trade-screen.md to code.
      expect(UiScreenIds.tradeScreen, 'GAME60001');
      expect(TradeScreen.screenId, UiScreenIds.tradeScreen);
    });

    test('RoutePaths.trade is "/game/trade" (registry contract)', () {
      expect(RoutePaths.trade, '/game/trade');
      expect(Routes.trade, RoutePaths.trade);
    });

    testWidgets(
      'Routes.generate dispatches RoutePaths.trade to a TradeScreen',
      (tester) async {
        await tester.pumpWidget(tradeHost());
        await pumpSettleCapped(tester);

        expect(find.text('open trade'), findsOneWidget);
        expect(find.byType(TradeScreen), findsNothing);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        expect(find.byType(TradeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'TradeScreen renders dark CtTopBar with literal title, label, and 18px '
      'trade icon (no observe mode)',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost());

        final topBarFinder = find.byKey(TradeScreenMarketKeys.topBarKey);
        expect(topBarFinder, findsOneWidget);

        final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
        expect(topBar.title, TradeScreenMarketKeys.topBarTitle);
        expect(topBar.backButtonLabel, TradeScreenMarketKeys.topBarBackLabel);
        expect(topBar.icon, isA<StrictAssetIcon>());
        final StrictAssetIcon icon = topBar.icon! as StrictAssetIcon;
        expect(icon.assetPath, TradeScreenMarketKeys.topBarIconAsset);
        expect(icon.width, 18);
        expect(icon.height, 18);

        // Two-tab body renders for non-observe sessions.
        expect(find.byKey(TradeScreenMarketKeys.tabsBodyKey), findsOneWidget);
        expect(find.byType(ObserveModeNotDefinedPanel), findsNothing);

        // Negative regression guard: no legacy light Material AppBar chrome.
        expect(find.byType(AppBar), findsNothing);
      },
    );

    testWidgets(
      'TradeScreen routes to ObserveModeNotDefinedPanel under global observe '
      'mode and hides the two-tab body and per-tab keyed bodies',
      (tester) async {
        await pumpAndOpenTradeScreen(tester, tradeHost(globalObserve: true));

        expect(find.byType(TradeScreen), findsOneWidget);
        // Top bar still paints — the observe override only swaps the body.
        expect(find.byKey(TradeScreenMarketKeys.topBarKey), findsOneWidget);

        final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
        expect(observePanelFinder, findsOneWidget);
        final ObserveModeNotDefinedPanel observePanel = tester
            .widget<ObserveModeNotDefinedPanel>(observePanelFinder);
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(observePanel.title, 'Trade');

        // Negative AC: none of the tab body keys must appear in observe mode.
        expect(find.byKey(TradeScreenMarketKeys.tabsBodyKey), findsNothing);
        expect(
          find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreenDealBookKeys.dealBookTabBodyKey),
          findsNothing,
        );
        expect(find.byType(CtTabStrip), findsNothing);
      },
    );

    testWidgets('CtTopBar back affordance pops back to the host route', (
      tester,
    ) async {
      await tester.pumpWidget(tradeHost());
      await pumpSettleCapped(tester);

      await tester.tap(find.text('open trade'));
      await pumpSettleCapped(tester);
      expect(find.byType(TradeScreen), findsOneWidget);

      final back = find.descendant(
        of: find.byType(CtTopBar),
        matching: find.byType(CtBackButton),
      );
      expect(back, findsOneWidget);
      await tester.tap(back);
      await pumpSettleCapped(tester);

      expect(find.byType(TradeScreen), findsNothing);
      expect(find.text('open trade'), findsOneWidget);
    });
  });
}
