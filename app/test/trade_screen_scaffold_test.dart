// Widget tests for the TradeScreen scaffold slice
// (Refs #2993 E1+E2+E3). SPEC/ui/trade-screen.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/themes.dart';
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
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    final result = getDebugInitGameResult();
    game = result.game;
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
    return ProviderScope(
      overrides: baseOverrides(globalObserve: globalObserve),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.editorialMonocle,
          onGenerateRoute: Routes.generate,
          home: Builder(
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
        ),
      ),
    );
  }

  Widget buildLeftRailHost() {
    return ProviderScope(
      overrides: baseOverrides(),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.editorialMonocle,
          onGenerateRoute: Routes.generate,
          home: Scaffold(
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

        // Scaffold placeholder body renders for non-observe sessions.
        expect(find.byKey(TradeScreen.placeholderBodyKey), findsOneWidget);
        expect(find.byType(ObserveModeNotDefinedPanel), findsNothing);

        // Negative regression guard: no legacy light Material AppBar chrome.
        expect(find.byType(AppBar), findsNothing);
      },
    );

    testWidgets(
      'TradeScreen routes to ObserveModeNotDefinedPanel under global observe '
      'mode and hides the scaffold placeholder body',
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

        // Negative AC: the placeholder body must NOT appear in observe mode.
        expect(find.byKey(TradeScreen.placeholderBodyKey), findsNothing);
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
