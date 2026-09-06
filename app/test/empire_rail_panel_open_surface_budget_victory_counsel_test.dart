// Victory + Counsel empire-rail open budget pins (Refs #4688, #4734 Slice J).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/screens/counsel/counsel_screen.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';
import 'empire_rail_panel_open_surface_budget_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(
      suiteId: 'empire_rail_surface_budget_victory',
    );
  });

  tearDownAll(() async {
    await gamesBox.close();
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
        empireRailL10nShell(
          overrides: overrides,
          child: const SizedBox.shrink(),
        ),
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
