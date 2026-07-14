// In-game shell flows (part2). SPEC/ui/in-game-shell-narrow.md, next-turn / pause / back.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/game_screen_test_support.dart';
import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: the narrow in-game shell assertions read only chrome (top bar,
  // side menu, left rail, players-bar gating, options dialog); the map canvas
  // just needs *a* mapViewData to mount. The lightweight game + minimal
  // mapViewData replace the ~7-11s getDebugInitGameResult() map generation.
  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_narrow_part2');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget buildGameScreen({required double width, required double height}) =>
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
        width: width,
        height: height,
        navigatorKey: appNavigatorKey,
      );

  Widget buildShellToGameFlow({
    required double width,
    required double height,
    TargetPlatform platform = TargetPlatform.android,
  }) => buildGameScreenShellToGameFlow(
    gamesBox: gamesBox,
    game: baseGame,
    mapViewData: lightMapViewData,
    width: width,
    height: height,
    platform: platform,
  );

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

        final turnNumber = baseGame.worldState.turnState.turnNumber;
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
      'pause menu opens modal with Resume and Exit to Main Menu actions (no Debug log)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreenWithPauseMenu(game: baseGame));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.menu).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Game Paused'), findsOneWidget);
        expect(find.text('Resume'), findsOneWidget);
        expect(find.text('Exit to Main Menu'), findsOneWidget);
        expect(find.text('Debug log'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'victory overlay shows and View final state hides it',
      (WidgetTester tester) async {
        final victoryGame = baseGame.copyWith(
          victory: VictoryState(
            winnerPlayerId: baseGame.players.first.id,
            type: VictoryType.military,
            turnNumber: baseGame.worldState.turnState.turnNumber,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: buildGameScreenShellOverrides(
              gamesBox: gamesBox,
              game: victoryGame,
              mapViewData: lightMapViewData,
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
