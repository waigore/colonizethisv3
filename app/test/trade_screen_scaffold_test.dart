// Widget tests for the TradeScreen scaffold slices
// (Refs #2993 E1+E2+E3 chrome + E4 two-tab body). SPEC/ui/trade-screen.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_empire_left_rail.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart' show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/features/game/shell_player_context.dart';
import 'package:colonizethis_app/features/game/widgets/observe_mode_not_defined_panel.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/app_shell_harness.dart';
import 'support/panel_test_fixtures.dart';
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

    Hive.init('./.dart_tool/test_hive_trade_screen');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  ShellPlayerContext globalObserveShellContext() {
    return const ShellPlayerContext(
      effectiveHumanPlayerId: null,
      viewingPlayerId: null,
      mapVisibilityMode: CtMapVisibilityMode.full,
      playerView: null,
      omniscientDetail: true,
      // Hides player chrome so `shellPanelsNotDefined(ref)` returns true and
      // body switches to ObserveModeNotDefinedPanel — matches the global
      // observe branch in `shellPlayerContextProvider` (observe-mode.md).
      showPlayerChrome: false,
      canMutateViaUi: false,
      debugCommandTargetPlayerId: null,
      inObservePhase: true,
      // ignore: avoid_hardcoded_strings_in_widgets
      observeBannerLabel: 'Observing: global',
      treasuryNotDefined: true,
      cargoNotDefined: true,
    );
  }

  baseOverrides({bool globalObserve = false}) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    if (globalObserve)
      shellPlayerContextProvider.overrideWithValue(
        globalObserveShellContext(),
      ),
  ];

  Widget buildTradeRouteHost({bool globalObserve = false}) {
    // Route host: drives `Navigator.pushNamed(RoutePaths.trade)` through
    // `Routes.generate`, so it uses the shared shell's `onGenerateRoute` +
    // `appNavigatorKey` seams and the `shellWrapper` seam to keep
    // `AppEventHandlerScope` above routing (Refs #3730).
    return buildAppShell(
      overrides: baseOverrides(globalObserve: globalObserve),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RoutePaths.trade,
                    arguments: <String, Object?>{
                      'game': game,
                      'humanPlayerId': humanPlayer.id,
                    },
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('open trade'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLeftRailHost() {
    return buildAppShell(
      overrides: baseOverrides(),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 20,
              top: 0,
              child: GameMapEmpireLeftRail(
                game: game,
                humanPlayerId: humanPlayer.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        await tester.pumpWidget(buildTradeRouteHost());
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
        await tester.pumpWidget(buildTradeRouteHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        final topBarFinder = find.byKey(TradeScreen.topBarKey);
        expect(topBarFinder, findsOneWidget);

        final CtTopBar topBar = tester.widget<CtTopBar>(topBarFinder);
        expect(topBar.title, TradeScreen.topBarTitle);
        expect(topBar.backButtonLabel, TradeScreen.topBarBackLabel);
        expect(topBar.icon, isA<StrictAssetIcon>());
        final StrictAssetIcon icon = topBar.icon! as StrictAssetIcon;
        expect(icon.assetPath, TradeScreen.topBarIconAsset);
        expect(icon.width, 18);
        expect(icon.height, 18);

        // Two-tab body renders for non-observe sessions.
        expect(find.byKey(TradeScreen.tabsBodyKey), findsOneWidget);
        expect(find.byType(ObserveModeNotDefinedPanel), findsNothing);

        // Negative regression guard: no legacy light Material AppBar chrome.
        expect(find.byType(AppBar), findsNothing);
      },
    );

    testWidgets(
      'TradeScreen routes to ObserveModeNotDefinedPanel under global observe '
      'mode and hides the two-tab body and per-tab keyed bodies',
      (tester) async {
        await tester.pumpWidget(buildTradeRouteHost(globalObserve: true));
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        expect(find.byType(TradeScreen), findsOneWidget);
        // Top bar still paints — the observe override only swaps the body.
        expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);

        final observePanelFinder = find.byType(ObserveModeNotDefinedPanel);
        expect(observePanelFinder, findsOneWidget);
        final ObserveModeNotDefinedPanel observePanel =
            tester.widget<ObserveModeNotDefinedPanel>(observePanelFinder);
        // ignore: avoid_hardcoded_strings_in_widgets
        expect(observePanel.title, 'Trade');

        // Negative AC: none of the tab body keys must appear in observe mode.
        expect(find.byKey(TradeScreen.tabsBodyKey), findsNothing);
        expect(find.byKey(TradeScreen.marketTabBodyKey), findsNothing);
        expect(find.byKey(TradeScreen.dealBookTabBodyKey), findsNothing);
        expect(find.byType(CtTabStrip), findsNothing);
      },
    );

    testWidgets(
      'CtTopBar back affordance pops back to the host route',
      (tester) async {
        await tester.pumpWidget(buildTradeRouteHost());
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
      },
    );
  });

  group('TradeScreen tab scaffold slice (Refs #2993 E4)', () {
    testWidgets(
      'tabs body hosts a CtTabStrip with literal Market + Deal Book labels in order',
      (tester) async {
        await tester.pumpWidget(buildTradeRouteHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        expect(find.byKey(TradeScreen.tabsBodyKey), findsOneWidget);

        final stripFinder = find.descendant(
          of: find.byKey(TradeScreen.tabsBodyKey),
          matching: find.byType(CtTabStrip),
        );
        expect(stripFinder, findsOneWidget);

        final CtTabStrip strip = tester.widget<CtTabStrip>(stripFinder);
        expect(strip.tabLabels, <String>[
          TradeScreen.marketTabLabel,
          TradeScreen.dealBookTabLabel,
        ]);
        expect(strip.tabViews.length, 2);
      },
    );

    testWidgets(
      'both Market and Deal Book tab body keys are mounted (IndexedStack '
      'keeps non-selected tab in tree, off-stage)',
      (tester) async {
        await tester.pumpWidget(buildTradeRouteHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        // Default selection foregrounds the Market tab; that body is on
        // stage and resolves under default `skipOffstage: true`.
        expect(find.byKey(TradeScreen.marketTabBodyKey), findsOneWidget);

        // Non-selected Deal Book tab is wrapped in Visibility(visible:
        // false) by IndexedStack and reads as off-stage to default
        // finders. Asserting `skipOffstage: false` confirms the widget
        // is still in the tree (state is preserved) — the contract that
        // lets E5/E6 swap each tab body in place without remounting the
        // tab strip.
        expect(
          find.byKey(TradeScreen.dealBookTabBodyKey, skipOffstage: false),
          findsOneWidget,
          reason:
              'IndexedStack mounts both tab bodies; the non-selected '
              'Deal Book body must remain in the element tree so E6 can '
              'replace it in place.',
        );
        // Conversely the off-stage Deal Book body must not be reachable
        // from default (skipOffstage: true) finders — that is the
        // visible/foregrounded contract for the default Market tab.
        expect(find.byKey(TradeScreen.dealBookTabBodyKey), findsNothing);
      },
    );

    testWidgets(
      'tapping the Deal Book label switches the foregrounded IndexedStack '
      'child to the Deal Book tab body',
      (tester) async {
        await tester.pumpWidget(buildTradeRouteHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        // Locate the IndexedStack created by CtTabStrip; verify default
        // selection is index 0 (Market).
        final stackFinder = find.descendant(
          of: find.byKey(TradeScreen.tabsBodyKey),
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
          matching: find.text(TradeScreen.dealBookTabLabel),
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
        await tester.pumpWidget(buildTradeRouteHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.text('open trade'));
        await pumpSettleCapped(tester);

        // Tap the Deal Book tab label to swap the on-stage child.
        final dealBookLabel = find.descendant(
          of: find.byType(CtTabStrip),
          matching: find.text(TradeScreen.dealBookTabLabel),
        );
        expect(dealBookLabel, findsOneWidget);
        await tester.tap(dealBookLabel);
        await pumpSettleCapped(tester);

        // After tap, the Deal Book tab body is on stage and renders the
        // live ledger content root keyed `tradeScreenDealBookContent`
        // (Refs #2993 E6) under the same `tradeScreenDealBookTabBody`
        // body root — the tab-body key remained stable so existing
        // tab-switch tests continue to pin the same affordance.
        expect(find.byKey(TradeScreen.dealBookTabBodyKey), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(TradeScreen.dealBookTabBodyKey),
            matching: find.byKey(TradeScreen.dealBookContentKey),
          ),
          findsOneWidget,
        );
        // Both bids and offers panel containers are always present in
        // the live content; their per-row contents are exercised by the
        // dedicated E6 panel tests in trade_screen_deal_book_tab_e6_test.dart.
        expect(find.byKey(TradeScreen.dealBookBidsPanelKey), findsOneWidget);
        expect(
          find.byKey(TradeScreen.dealBookOffersPanelKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookBidsTotalsKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookOffersTotalsKey),
          findsOneWidget,
        );
      },
    );
  });

  group('GameMapEmpireLeftRail Trade button (Refs #2993 E3)', () {
    testWidgets(
      'rail exposes kEmpireTradeButtonKey between Production and '
      'Civilian Units',
      (tester) async {
        await tester.pumpWidget(buildLeftRailHost());
        await pumpSettleCapped(tester);

        final trade = find.byKey(kEmpireTradeButtonKey);
        expect(trade, findsOneWidget);

        final productionTopLeft = tester
            .getTopLeft(find.byKey(kEmpireProductionButtonKey));
        final tradeTopLeft = tester.getTopLeft(trade);
        final civilianTopLeft = tester
            .getTopLeft(find.byKey(kEmpireCivilianUnitsButtonKey));

        // Vertical stack ordering: Production -> Trade -> Civilian Units.
        expect(
          tradeTopLeft.dy,
          greaterThan(productionTopLeft.dy),
          reason: 'Trade button sits below Production per SPEC #2993 R4.',
        );
        expect(
          civilianTopLeft.dy,
          greaterThan(tradeTopLeft.dy),
          reason: 'Civilian Units sits below Trade per SPEC #2993 R4.',
        );
      },
    );

    testWidgets(
      'tapping Trade navigates to TradeScreen via Routes.generate',
      (tester) async {
        await tester.pumpWidget(buildLeftRailHost());
        await pumpSettleCapped(tester);

        await tester.tap(find.byKey(kEmpireTradeButtonKey));
        await pumpSettleCapped(tester);

        expect(find.byType(TradeScreen), findsOneWidget);
        expect(find.byKey(TradeScreen.topBarKey), findsOneWidget);
      },
    );
  });
}
