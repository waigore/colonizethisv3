// Pump harness for GameSideMenu spec tests (Refs #4352, #4734 Slice J).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

Widget gameSideMenuSpecsWrap({
  required Box<dynamic> gamesBox,
  required Game? activeGame,
  required AppEventBus bus,
  bool sideMenuOpen = true,
  required VoidCallback onClose,
  Map<String, Widget Function(BuildContext)> routes = const {},
}) {
  return buildAppShell(
    overrides: [
      gamesBoxProvider.overrideWith((ref) => gamesBox),
      gameServiceProvider.overrideWith(
        (ref) => GameService(gamesBox, GameSaveAdapter()),
      ),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(activeGame)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      appEventBusProvider.overrideWith((ref) => bus),
    ],
    navigatorKey: appNavigatorKey,
    onGenerateRoute: routes.isEmpty
        ? null
        : (settings) {
            final builder = routes[settings.name];
            if (builder == null) {
              return null;
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: builder,
            );
          },
    shellWrapper: (app) => AppEventHandlerScope(child: app),
    child: Scaffold(
      body: Stack(
        children: [
          GameSideMenu(sideMenuOpen: sideMenuOpen, onClose: onClose),
        ],
      ),
    ),
  );
}
