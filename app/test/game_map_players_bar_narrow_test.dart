// Narrow-viewport contract for the in-game shell players bar (Refs #2870 S3).
//
// SPEC: `SPEC/ui/empire-overview.md` § Players bar (acceptance line:
// *Given the in-game map is visible with two GP players, when the narrow
// layout (`MediaQuery.size.width < kNarrowBreakpoint`) renders, then the
// players bar is not mounted*).
// SPEC: `SPEC/ui/mobile-adaptation.md` § In-game shell (Players bar:
// "Hidden — not present in widget tree" at < 600 dp).
//
// These tests pin the GameScreen-level gating defined in
// `game_map_area_part2.dart` (`if (!isNarrow && widget.game.victory == null)`):
//
//   - Positive: when the host viewport is below `kNarrowBreakpoint`, the
//     players-bar widget is absent from the widget tree.
//   - Negative (regression): when the host viewport is at or above
//     `kNarrowBreakpoint`, the players-bar widget is mounted.
//   - Negative (regression): when the game has a `victory` set, the bar
//     stays hidden even on a wide viewport (the chip column would otherwise
//     paint behind the victory overlay scrim — see empire-overview.md
//     Players bar AC).
//
// Companion: see `game_map_players_bar_test.dart` for the standalone widget
// contract (chip ordering, swatch tint, score format).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart'
    show GameScreen, kGameMapPlayersBarKey;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
    Hive.init('./.dart_tool/test_hive_players_bar_narrow');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  gameShellOverrides({required Game game}) => [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      mapViewDataProvider.overrideWith((ref) => debugResult.mapViewData),
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
    ];

  Widget buildGameScreen({
    required Game game,
    required double width,
    required double height,
  }) {
    return ProviderScope(
      overrides: gameShellOverrides(game: game),
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

  group('GameMapPlayersBar narrow-viewport gating (Refs #2870 S3)', () {
    testWidgets(
      'positive: bar is absent from the widget tree below kNarrowBreakpoint',
      (WidgetTester tester) async {
        // Sanity check on the breakpoint itself; if this constant changes,
        // every narrow-viewport AC across the app needs revisiting.
        expect(kNarrowBreakpoint, 600.0);
        const double narrowWidth = kNarrowBreakpoint - 1.0;

        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(narrowWidth * dpr, 700 * dpr);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          buildGameScreen(
            game: debugResult.game,
            width: narrowWidth,
            height: 700,
          ),
        );
        await tester.pump();

        expect(
          find.byKey(kGameMapPlayersBarKey),
          findsNothing,
          reason:
              'Players bar must be hidden on viewports < kNarrowBreakpoint per '
              'SPEC/ui/empire-overview.md § Players bar and '
              'SPEC/ui/mobile-adaptation.md § In-game shell (issue #2870 S3).',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'negative regression: bar is mounted at the wide breakpoint baseline',
      (WidgetTester tester) async {
        // Use a comfortably wide viewport so all chrome resolves like the
        // production wide layout (mirrors game_screen_narrow_test.dart's
        // 1500 × 700 reference setup).
        const double wideWidth = 1500.0;

        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(wideWidth * dpr, 700 * dpr);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          buildGameScreen(
            game: debugResult.game,
            width: wideWidth,
            height: 700,
          ),
        );
        await tester.pump();

        expect(
          find.byKey(kGameMapPlayersBarKey),
          findsOneWidget,
          reason:
              'Players bar must remain mounted on wide viewports '
              '(>= kNarrowBreakpoint) so the wide chrome contract from '
              'SPEC/ui/empire-overview.md § Players bar still holds.',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'negative regression: bar stays hidden on wide viewports under victory',
      (WidgetTester tester) async {
        // SPEC: empire-overview.md § Players bar — "Given Game.victory != null,
        // when the map stack renders, then the players bar is not mounted (the
        // chip column is hidden so it does not paint behind the victory
        // overlay scrim)." This regression guard pairs the existing
        // wide-baseline AC with the victory-state suppression so both gating
        // predicates in `game_map_area_part2.dart` (`!isNarrow &&
        // widget.game.victory == null`) stay covered by tests.
        const double wideWidth = 1500.0;
        final victoryGame = debugResult.game.copyWith(
          victory: VictoryState(
            winnerPlayerId: debugResult.game.players.first.id,
            type: VictoryType.military,
            turnNumber:
                debugResult.game.worldState.turnState.turnNumber,
          ),
        );

        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(wideWidth * dpr, 700 * dpr);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          buildGameScreen(
            game: victoryGame,
            width: wideWidth,
            height: 700,
          ),
        );
        await tester.pump();

        expect(
          find.byKey(kGameMapPlayersBarKey),
          findsNothing,
          reason:
              'Players bar must stay hidden when Game.victory != null even on '
              'wide viewports per SPEC/ui/empire-overview.md § Players bar '
              '(victory-overlay scrim regression guard).',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
