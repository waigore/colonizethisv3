// Shell-entry capital auto-center + home-to-capital observe gating.
// SPEC/ui/empire-overview.md § Initial map viewport (shell entry),
// § Home-to-capital button. SPEC/ui/observe-mode.md. Refs #3616.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/game_map_corner_controls.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('GameMapAreaStateLogic.resolveShellEntryAutoCenter (Refs #3616)', () {
    Game gameWith({CapitalTile? gp1Capital, CapitalTile? gp2Capital}) {
      return Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: const RegionData(provinces: [], units: []),
          newWorld: const RegionData(provinces: [], units: []),
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'Human',
            isHuman: true,
            capitalTile: gp1Capital,
          ),
          Player(
            id: 'gp2',
            displayName: 'Rival',
            isHuman: false,
            capitalTile: gp2Capital,
          ),
        ],
        minorNations: const [],
        tribes: const [],
      );
    }

    test('oldWorld capital resolves region index 0 and capital tile key', () {
      const capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'p1',
        x: 2,
        y: 3,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(gp1Capital: capital),
        currentPlayerId: 'gp1',
      );
      expect(target, isNotNull);
      expect(target!.regionIndex, 0);
      expect(target.tileKey, capital.toTileKey());
    });

    test('newWorld capital resolves region index 1', () {
      const capital = CapitalTile(
        regionId: 'newWorld',
        provinceId: 'p9',
        x: 5,
        y: 6,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(gp1Capital: capital),
        currentPlayerId: 'gp1',
      );
      expect(target, isNotNull);
      expect(target!.regionIndex, 1);
      expect(target.tileKey, capital.toTileKey());
    });

    test('null currentPlayerId (global observe) returns null', () {
      const capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'p1',
        x: 0,
        y: 0,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(gp1Capital: capital),
        currentPlayerId: null,
      );
      expect(target, isNull);
    });

    test('player without capitalTile returns null', () {
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(),
        currentPlayerId: 'gp1',
      );
      expect(target, isNull);
    });

    test('unknown player id returns null', () {
      const capital = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'p1',
        x: 1,
        y: 1,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(gp1Capital: capital),
        currentPlayerId: 'nope',
      );
      expect(target, isNull);
    });

    test('player observe targets the observed GP capital', () {
      const gp2Capital = CapitalTile(
        regionId: 'newWorld',
        provinceId: 'p2',
        x: 4,
        y: 4,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(
          gp1Capital: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'p1',
            x: 0,
            y: 0,
          ),
          gp2Capital: gp2Capital,
        ),
        currentPlayerId: 'gp2',
      );
      expect(target, isNotNull);
      expect(target!.tileKey, gp2Capital.toTileKey());
      expect(target.regionIndex, 1);
    });

    test('uses the current (reassigned) capital tile, not turn-0 value', () {
      const reassigned = CapitalTile(
        regionId: 'newWorld',
        provinceId: 'p77',
        x: 7,
        y: 8,
      );
      final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
        game: gameWith(gp1Capital: reassigned),
        currentPlayerId: 'gp1',
      );
      expect(target, isNotNull);
      expect(target!.tileKey, reassigned.toTileKey());
    });
  });

  group('GameMapArea shell-entry auto-center (widget) (Refs #3616)', () {
    // Refs #3656: the widget assertions read only chrome — the capital
    // auto-center highlight, the home-to-capital control, observe gating — not
    // generated map cells/topology. A lightweight game (human with a capital +
    // an AI opponent) and a minimal mapViewData replace the ~7-11s
    // getDebugInitGameResult() map generation that just let the canvas mount.
    final Game chromeGame = buildMapAreaChromeTestGame();
    final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
    late Box<dynamic> gamesBox;

    setUpAll(() async {
      Hive.init('./.dart_tool/test_hive_shell_entry_center');
      gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(game, mapViewData),
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              theme: AppThemes.editorialMonocle,
              home: const MediaQuery(
                data: MediaQueryData(size: Size(1500, 700)),
                child: GameScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
    }

    testWidgets(
      'AC: mount sets secondary highlight on the current player capital and '
      'does not open the province overlay',
      (tester) async {
        final human = chromeGame.players.firstWhere((p) => p.isHuman);
        final capital = human.capitalTile;
        expect(
          capital,
          isNotNull,
          reason: 'lightweight fixture human player must have a capital tile',
        );
        final container = await pumpShell(
          tester,
          game: chromeGame,
          mapViewData: lightMapViewData,
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
          game: chromeGame,
          mapViewData: lightMapViewData,
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
          game: chromeGame,
          mapViewData: lightMapViewData,
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
          game: chromeGame,
          mapViewData: lightMapViewData,
        );
        container
            .read(observeSessionProvider.notifier)
            .setModePlayer(chromeGame.players.first.id);
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
