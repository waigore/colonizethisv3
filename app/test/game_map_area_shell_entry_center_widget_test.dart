// Shell-entry capital auto-center widget chrome (Refs #3616, #3656).
// SPEC/ui/empire-overview.md § Initial map viewport (shell entry),
// § Home-to-capital button. SPEC/ui/observe-mode.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  group('GameMapArea shell-entry auto-center (widget) (Refs #3616)', () {
    // Refs #3656: this group only asserts shell-entry chrome derived from
    // `game.players` + observe state (secondary highlight on the current
    // player's capital tile, province overlay closed, home-to-capital gating).
    // The lightweight game + minimal mapViewData replace the ~7-11s
    // getDebugInitGameResult() map generation with identical behaviour — the
    // capital-center camera move and highlight paint safely no-op for the
    // off-map capital tile.
    final Game lightweightGame = buildShellEntryCenterTestGame();
    final InitGameMapViewData mapViewData = buildLightweightMapViewData();
    late Box<dynamic> gamesBox;

    setUpAll(() async {
      gamesBox = await openAppTestHiveBox(suiteId: 'shell_entry_center');
    });

    overrides(Game game, InitGameMapViewData? mapViewData) => [
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
      treasurySummaryProvider.overrideWith(
        (ref) => const TreasurySummary(treasury: 0),
      ),
    ];

    Future<ProviderContainer> pumpShell(
      WidgetTester tester, {
      required Game game,
      required InitGameMapViewData? mapViewData,
    }) async {
      final dpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
      addTearDown(tester.view.reset);
      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      await tester.pumpWidget(
        buildAppShell(
          overrides: overrides(game, mapViewData),
          navigatorKey: appNavigatorKey,
          viewport: const Size(1500, 700),
          shellWrapper: (app) => AppEventHandlerScope(child: app),
          child: const GameScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();
      return ProviderScope.containerOf(tester.element(find.byType(GameScreen)));
    }

    testWidgets(
      'AC: mount sets secondary highlight on the current player capital and '
      'does not open the province overlay',
      (tester) async {
        final human = lightweightGame.players.firstWhere((p) => p.isHuman);
        final capital = human.capitalTile;
        expect(
          capital,
          isNotNull,
          reason: 'lightweight fixture human player must have a capital tile',
        );
        final container = await pumpShell(
          tester,
          game: lightweightGame,
          mapViewData: mapViewData,
        );
        final panel = container.read(mapProvincePanelProvider);
        expect(panel.secondaryHighlightTileKey, capital!.toTileKey());
        expect(panel.overlayOpen, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: home-to-capital button enabled in normal play',
      (tester) async {
        await pumpShell(
          tester,
          game: lightweightGame,
          mapViewData: mapViewData,
        );
        final controls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(controls.homeToCapitalEnabled, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: global observe disables the home-to-capital button',
      (tester) async {
        final container = await pumpShell(
          tester,
          game: lightweightGame,
          mapViewData: mapViewData,
        );
        container.read(observeSessionProvider.notifier).setModeGlobal();
        await tester.pump();
        final controls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(controls.homeToCapitalEnabled, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: player observe enables the home-to-capital button',
      (tester) async {
        final container = await pumpShell(
          tester,
          game: lightweightGame,
          mapViewData: mapViewData,
        );
        container
            .read(observeSessionProvider.notifier)
            .setModePlayer(lightweightGame.players.first.id);
        await tester.pump();
        final controls = tester.widget<GameMapCornerControls>(
          find.byType(GameMapCornerControls),
        );
        expect(controls.homeToCapitalEnabled, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
