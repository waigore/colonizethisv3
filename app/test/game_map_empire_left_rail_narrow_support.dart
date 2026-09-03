import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

List<Override> overrides({
  required Game game,
  required Box<dynamic> gamesBox,
  bool debugConsoleEnabled = false,
}) => [
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  gameServiceProvider.overrideWith(
    (ref) => GameService(gamesBox, GameSaveAdapter()),
  ),
  currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
  currentOrdersProvider.overrideWith(
    () => CurrentOrdersNotifier(const Orders()),
  ),
  availableWorkTargetIdsForUnitProvider.overrideWith(
    (ref, _) => const <String>[],
  ),
  appEventBusProvider.overrideWith((ref) {
    final bus = AppEventBus.create();
    ref.onDispose(bus.dispose);
    return bus;
  }),
  debugConsoleEnabledProvider.overrideWithValue(debugConsoleEnabled),
];

String _humanId(Game game) => game.players.where((p) => p.isHuman).isNotEmpty
    ? game.players.where((p) => p.isHuman).first.id
    : game.players.first.id;

Widget railScaffold({
  required Game game,
  required Box<dynamic> gamesBox,
  required bool narrow,
  bool debugConsoleEnabled = false,
}) {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  return buildAppShell(
    overrides: overrides(
      game: game,
      gamesBox: gamesBox,
      debugConsoleEnabled: debugConsoleEnabled,
    ),
    navigatorKey: appNavigatorKey,
    shellWrapper: (app) => AppEventHandlerScope(child: app),
    child: Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            left: 20,
            top: 0,
            child: GameMapEmpireLeftRail(
              game: game,
              humanPlayerId: _humanId(game),
              narrow: narrow,
            ),
          ),
        ],
      ),
    ),
  );
}

const List<Key> railButtonKeys = <Key>[
  kEmpireProductionButtonKey,
  kEmpireTradeButtonKey,
  kEmpireDevelopmentButtonKey,
  kEmpireCivilianUnitsButtonKey,
  kEmpireMilitaryUnitsButtonKey,
  kEmpireNavalUnitsButtonKey,
  kEmpireDiplomacyButtonKey,
  kEmpireTechnologyButtonKey,
  kEmpireVictoryButtonKey,
];
