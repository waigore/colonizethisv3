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

List<Override> empireLeftRailOverrides({
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

String empireLeftRailHumanId(Game game) =>
    game.players.where((p) => p.isHuman).isNotEmpty
    ? game.players.where((p) => p.isHuman).first.id
    : game.players.first.id;

Widget empireLeftRailScaffold({
  required Game game,
  required Box<dynamic> gamesBox,
  bool debugConsoleEnabled = false,
  RouteFactory? onGenerateRoute,
  Size? viewport,
  Widget? child,
}) {
  return buildAppShell(
    overrides: empireLeftRailOverrides(
      game: game,
      gamesBox: gamesBox,
      debugConsoleEnabled: debugConsoleEnabled,
    ),
    navigatorKey: appNavigatorKey,
    onGenerateRoute: onGenerateRoute,
    viewport: viewport,
    shellWrapper: (app) => AppEventHandlerScope(child: app),
    child:
        child ??
        Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 20,
                top: 0,
                child: GameMapEmpireLeftRail(
                  game: game,
                  humanPlayerId: empireLeftRailHumanId(game),
                ),
              ),
            ],
          ),
        ),
  );
}

class EmpireLeftRailOnlyHost extends StatelessWidget {
  const EmpireLeftRailOnlyHost({
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 20,
            top: 0,
            child: GameMapEmpireLeftRail(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
          ),
        ],
      ),
    );
  }
}

const List<Key> empireLeftRailButtonKeys = <Key>[
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
