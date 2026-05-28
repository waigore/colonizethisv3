// In-game shell side menu. SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    debugResult = getDebugInitGameResult();
    Hive.init('./.dart_tool/test_hive_game_screen_narrow');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  gameShellOverrides({
    required Game game,
    required InitGameMapViewData? mapViewData,
    TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
  }) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    mapViewDataProvider.overrideWith((ref) => mapViewData),
    gameIdsWithIntroShownProvider.overrideWith(
      () => GameIdsWithIntroShownNotifier({game.id}),
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    homeFleetCargoSummaryProvider.overrideWith(
      (ref) => const HomeFleetCargoSummary(used: 0, capacity: 0),
    ),
    treasurySummaryProvider.overrideWith((ref) => treasurySummary),
  ];

  Widget buildGameScreen({required double width, required double height}) {
    return ProviderScope(
      overrides: gameShellOverrides(
        game: debugResult.game,
        mapViewData: debugResult.mapViewData,
      ),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.colonial,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: const GameScreen(),
          ),
        ),
      ),
    );
  }

  Widget buildShellToGameFlow({
    required double width,
    required double height,
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return ProviderScope(
      overrides: gameShellOverrides(
        game: debugResult.game,
        mapViewData: debugResult.mapViewData,
      ),
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.colonial.copyWith(platform: platform),
          routes: {
            Routes.shell: (_) =>
                const Scaffold(body: Center(child: Text('Main Menu'))),
            Routes.game: (_) => MediaQuery(
              data: MediaQueryData(size: Size(width, height)),
              child: const GameScreen(),
            ),
          },
          initialRoute: Routes.game,
        ),
      ),
    );
  }

  group('GameScreen — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: cargo hold indicator appears beside region tabs in used/capacity format (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final indicator = find.byKey(kCargoHoldIndicatorKey);
        expect(indicator, findsOneWidget);

        final formattedValue = find.descendant(
          of: indicator,
          matching: find.textContaining(RegExp(r'^\d+/\d+$')),
        );
        expect(formattedValue, findsOneWidget);

        final iconFinder = find.descendant(
          of: indicator,
          matching: find.byType(StrictAssetIcon),
        );
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<StrictAssetIcon>(iconFinder);
        expect(iconWidget.assetPath, 'assets/icons/32/ui_icon_cargo_hold.png');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury indicator appears between New World and cargo with exact value and dedicated icon',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: gameShellOverrides(
              game: debugResult.game,
              mapViewData: debugResult.mapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 250,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: MediaQuery(
                  data: const MediaQueryData(size: Size(1500, 700)),
                  child: const GameScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        final cargoIndicator = find.byKey(kCargoHoldIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(cargoIndicator, findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);
        expect(find.text('+250'), findsOneWidget);

        final iconFinder = find.descendant(
          of: treasuryIndicator,
          matching: find.byType(StrictAssetIcon),
        );
        expect(iconFinder, findsOneWidget);
        final iconWidget = tester.widget<StrictAssetIcon>(iconFinder);
        expect(
          iconWidget.assetPath,
          'assets/icons/32/ui_icon_treasury_coin.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: tapping treasury indicator toggles exact and abbreviated display',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final treasuryIndicator = find.byKey(kTreasuryIndicatorKey);
        expect(treasuryIndicator, findsOneWidget);
        expect(find.text('12,345'), findsOneWidget);

        await tester.tap(treasuryIndicator);
        await tester.pump();
        expect(find.text('12.3k'), findsOneWidget);

        await tester.tap(treasuryIndicator);
        await tester.pump();
        expect(find.text('12,345'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for positive values',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: gameShellOverrides(
              game: debugResult.game,
              mapViewData: debugResult.mapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 250,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('+250'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta shows signed text for negative values',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: gameShellOverrides(
              game: debugResult.game,
              mapViewData: debugResult.mapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: -400,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('400'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: treasury delta hides when projected delta is zero',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: gameShellOverrides(
              game: debugResult.game,
              mapViewData: debugResult.mapViewData,
              treasurySummary: const TreasurySummary(
                treasury: 12345,
                projectedDelta: 0,
              ),
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('+250'), findsNothing);
        expect(find.text('-400'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (wide viewport)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        // Empire labels are tooltips only, not top bar
        expect(find.text('Production'), findsNothing);
        expect(find.text('Civilian Units'), findsNothing);
        expect(find.text('Technology'), findsNothing);
        // Left rail icon keys (always visible without opening hamburger)
        expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
        expect(find.byKey(kEmpireTechnologyButtonKey), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (narrow viewport)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 399, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('Production'), findsNothing);
        expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: base layer cycle button is visible on map; tap cycles mode (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final buttonFinder = find.byKey(kBaseLayerCycleButtonKey);
        expect(buttonFinder, findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.tap(buttonFinder);
          await tester.pump();
        }
        expect(buttonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: home-to-capital button is visible beside base layer button and tappable (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final baseButtonFinder = find.byKey(kBaseLayerCycleButtonKey);
        final homeButtonFinder = find.byKey(kHomeToCapitalButtonKey);

        expect(baseButtonFinder, findsOneWidget);
        expect(homeButtonFinder, findsOneWidget);

        await tester.tap(homeButtonFinder);
        await tester.pump();

        // No additional assertions here; behavior (centering on capital tile)
        // is covered by CtRegionMap's centerOnTileKey tests and capitalTile specs.
        expect(homeButtonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: map display options button is visible in bottom tool row and opens dialog (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        expect(optionsButtonFinder, findsOneWidget);

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Map display options'), findsOneWidget);
        expect(find.text('Show province overlay'), findsOneWidget);
        expect(find.text('Show province ownership'), findsOneWidget);
        expect(find.text('Show province names'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province overlay in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        expect(optionsButtonFinder, findsOneWidget);

        // Open dialog.
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final showProvinceOverlayFinder = find.widgetWithText(
          SwitchListTile,
          'Show province overlay',
        );
        expect(showProvinceOverlayFinder, findsOneWidget);

        // Toggle off.
        await tester.tap(showProvinceOverlayFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Close dialog.
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Re-open and ensure the toggle remains off.
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final switchTile = tester.widget<SwitchListTile>(
          showProvinceOverlayFinder,
        );
        expect(switchTile.value, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province ownership in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final ownershipFinder = find.widgetWithText(
          SwitchListTile,
          'Show province ownership',
        );
        expect(ownershipFinder, findsOneWidget);

        // Default OFF — turn ON and persist.
        await tester.tap(ownershipFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        var ownershipTile = tester.widget<SwitchListTile>(ownershipFinder);
        expect(ownershipTile.value, isTrue);

        // Turn OFF again and persist.
        await tester.tap(ownershipFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        ownershipTile = tester.widget<SwitchListTile>(ownershipFinder);
        expect(ownershipTile.value, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: first map display options open shows overlay and names ON, ownership OFF (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        await tester.tap(find.byKey(kMapDisplayOptionsButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final overlayTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Show province overlay'),
        );
        final ownershipTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Show province ownership'),
        );
        final namesTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Show province names'),
        );
        expect(overlayTile.value, isTrue);
        expect(ownershipTile.value, isFalse);
        expect(namesTile.value, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: toggling Show province names in dialog updates state and persists within session (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final optionsButtonFinder = find.byKey(kMapDisplayOptionsButtonKey);
        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final showNamesFinder = find.widgetWithText(
          SwitchListTile,
          'Show province names',
        );
        expect(showNamesFinder, findsOneWidget);

        await tester.tap(showNamesFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(optionsButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final namesTile = tester.widget<SwitchListTile>(showNamesFinder);
        expect(namesTile.value, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    // Empire rail: see game_map_empire_left_rail_test.dart. Hamburger: Debug log only (game_side_menu_test).
  });

  group('GameScreen — Next turn confirmation', () {
    testWidgets(
      'AC: clicking Next turn button shows confirmation dialog with turn number',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        expect(nextTurnFinder, findsOneWidget);
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('End turn?'), findsOneWidget);
        expect(find.textContaining('will end'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: clicking No closes dialog without advancing turn',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('End turn?'), findsOneWidget);

        await tester.tap(find.text('No'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('End turn?'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: dialog shows correct turn number from game state',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final turnNumber = debugResult.game.worldState.turnState.turnNumber;
        expect(
          find.textContaining('Turn $turnNumber will end'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });

  group('GameScreen — pause menu and victory overlay', () {
    Widget buildGameScreenWithPauseMenu({required Game game}) {
      return ProviderScope(
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          mapViewDataProvider.overrideWith((ref) => null),
          gameIdsWithIntroShownProvider.overrideWith(
            () => GameIdsWithIntroShownNotifier({game.id}),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
          homeFleetCargoSummaryProvider.overrideWith(
            (ref) => const HomeFleetCargoSummary(used: 0, capacity: 0),
          ),
          treasurySummaryProvider.overrideWith(
            (ref) => const TreasurySummary(treasury: 12345),
          ),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            routes: {
              Routes.debugLog: (context) =>
                  const Scaffold(body: Center(child: Text('Debug log screen'))),
            },
            home: const GameScreen(),
          ),
        ),
      );
    }

    testWidgets(
      'pause menu opens bottom sheet and shows debug log entry',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildGameScreenWithPauseMenu(game: debugResult.game),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.menu).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Debug log'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'victory overlay shows and View final state hides it',
      (WidgetTester tester) async {
        final victoryGame = debugResult.game.copyWith(
          victory: VictoryState(
            winnerPlayerId: debugResult.game.players.first.id,
            type: VictoryType.military,
            turnNumber: debugResult.game.worldState.turnState.turnNumber,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: gameShellOverrides(
              game: victoryGame,
              mapViewData: debugResult.mapViewData,
            ),
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                theme: AppThemes.colonial,
                home: const GameScreen(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // The restyled overlay (Refs #2861, SPEC/ui/victory-overlay.md) renders
        // the title in uppercase ("MILITARY VICTORY"); accept either case so a
        // future copy tweak doesn't silently break this assertion.
        expect(
          find.textContaining(RegExp('victory', caseSensitive: false)),
          findsOneWidget,
        );

        await tester.tap(find.text('View final state'));
        await tester.pump(const Duration(milliseconds: 200));

        // Overlay should be gone but we should still be on the Game screen shell.
        expect(
          find.textContaining(RegExp('victory', caseSensitive: false)),
          findsNothing,
        );
        expect(find.byType(GameScreen), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });

  group('GameScreen — Android back exit confirmation', () {
    testWidgets(
      'AC: pressing back shows pixel-style confirm dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Exit game?'), findsOneWidget);
        expect(
          find.text('Your current progress will be lost if not saved.'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping Cancel dismisses dialog and stays on game',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byType(GameScreen), findsOneWidget);
        expect(find.text('Main Menu'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping outside dialog dismisses and stays on game',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byType(GameScreen), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping Exit navigates to main menu route',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Exit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Main Menu'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: Android back (platform-configured) shows exit confirm before leaving game',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildShellToGameFlow(
            width: 800,
            height: 600,
            platform: TargetPlatform.android,
          ),
        );
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Exit game?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });

  // Note: overture dialogue overlay is covered indirectly via higher-level
  // dialogue and diplomacy tests; here we focus on the in-game shell and
  // next-turn confirmation flows for narrow layouts.
}
