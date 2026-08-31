// Full-widget open-to-interactive profiling anchors for empire-rail GAME* panels
// (Refs #4688 Slice 10).
//
// CI surrogate for profile/release DevTools sessions on binding hosts: measures
// pump-to-interactive on the representative dual-region campaign fixture.
// Not a debug wall-clock 1s assertion — the standing 1 000 ms gate is
// profile/release on Linux desktop and Android emulator (see enforcement boundary
// in SPEC/program/app-ui-wiring.md).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_contract_market.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';
import 'development_panel_test_support.dart';
import 'empire_rail_panel_open_surface_budget_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'empire_rail_surface_budget_v2');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets('empire-rail GAME20001 Production cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildDevelopmentPanelGoldenGame();
    final player = game.playerById(kPanelTestHumanPlayerId)!;
    final overrides = productionPanelOverrides(game, gamesBox);

    Future<void> mount() async {
      await tester.pumpWidget(
        empireRailL10nShell(
          overrides: overrides,
          child: ProductionScreen(
            game: game,
            player: player,
            attachGameToUiListener: false,
          ),
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await tester.pumpWidget(
        empireRailL10nShell(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.text('Available'),
    );
  });

  testWidgets('empire-rail GAME60001 Trade cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildTradePanelTestGame();
    final player = game.players.first;
    final overrides = [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
    ];

    Future<void> mount() async {
      await tester.pumpWidget(
        empireRailL10nShell(
          overrides: overrides,
          child: TradeScreen(game: game, player: player),
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await tester.pumpWidget(
        empireRailL10nShell(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
    );
  });

  testWidgets('empire-rail GAME30001 Diplomacy cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildDiplomacyScreenTestGame();
    final humanPlayerId = game.players.first.id;
    final overrides = [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    ];

    Future<void> mount() async {
      await tester.pumpWidget(
        empireRailL10nShell(
          overrides: overrides,
          child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await tester.pumpWidget(
        empireRailL10nShell(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.text('Great Powers'),
    );
  });

  testWidgets('empire-rail GAME40001 Technology cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildTechnologyPanelTestGame();
    final player = game.players.first;
    final overrides = [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ];

    Future<void> mount() async {
      await tester.pumpWidget(
        empireRailL10nShell(
          overrides: overrides,
          child: TechnologyScreen(game: game, player: player),
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await tester.pumpWidget(
        empireRailL10nShell(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.text('Slots'),
    );
  });

  testWidgets('empire-rail GAME70001 Victory cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildPanelTestGame();
    final overrides = [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    ];

    Future<void> mount() async {
      await tester.pumpWidget(
        empireRailL10nShell(
          overrides: overrides,
          child: Scaffold(
            body: VictoryScreenBody(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await tester.pumpWidget(
        empireRailL10nShell(overrides: overrides, child: const SizedBox.shrink()),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.byKey(VictoryScreenKeys.standingsSectionKey),
    );
  });

  testWidgets('empire-rail GAME90001 Counsel cold and warm open (Refs #4688)', (
    WidgetTester tester,
  ) async {
    final game = buildPanelTestGame();
    final bus = AppEventBus.create();
    final overrides = [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      appEventBusProvider.overrideWith((ref) {
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ];

    Future<void> mount() async {
      await pumpAppShell(
        tester,
        overrides: overrides,
        navigatorKey: appNavigatorKey,
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: CounselScreen(
          game: game,
          humanPlayerId: game.players.first.id,
        ),
      );
      await pumpSettleCapped(tester);
    }

    Future<void> unmount() async {
      await pumpAppShell(
        tester,
        overrides: overrides,
        navigatorKey: appNavigatorKey,
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: const SizedBox.shrink(),
      );
      await tester.pump();
    }

    await coldWarmEmpireRailPanelOpenCycle(
      tester,
      mountPanel: mount,
      unmountPanel: unmount,
      interactiveProbe: find.text('Counsel'),
    );
  });
}
