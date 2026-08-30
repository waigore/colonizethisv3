// Host pumps for TradeScreen scaffold / left-rail tests (Refs #4352).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'trade_screen_test_support.dart';
import 'widget_test_pumps.dart';

List<Override> tradeScaffoldBaseOverrides({
  required Game game,
  required Box<dynamic> gamesBox,
  bool globalObserve = false,
}) {
  return [
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
        tradeTestGlobalObserveShellContext(),
      ),
  ];
}

Widget buildTradeRouteHost({
  required Game game,
  required Player humanPlayer,
  required Box<dynamic> gamesBox,
  bool globalObserve = false,
}) {
  return buildAppShell(
    overrides: tradeScaffoldBaseOverrides(
      game: game,
      gamesBox: gamesBox,
      globalObserve: globalObserve,
    ),
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

Widget buildTradeLeftRailHost({
  required Game game,
  required Player humanPlayer,
  required Box<dynamic> gamesBox,
}) {
  return buildAppShell(
    overrides: tradeScaffoldBaseOverrides(game: game, gamesBox: gamesBox),
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

Future<void> pumpAndOpenTradeScreen(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await pumpSettleCapped(tester);
  await tester.tap(find.text('open trade'));
  await pumpSettleCapped(tester);
}
