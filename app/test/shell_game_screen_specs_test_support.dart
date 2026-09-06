// Shell/game screen pump hosts (Refs #4305).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/shell_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_app/core/utils/state_toggle_notifier.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'game_screen_test_support.dart';

class ShellGameScreenSpecsStubBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final shellGameScreenSpecsStubService =
    GameService(ShellGameScreenSpecsStubBox(), GameSaveAdapter());

Widget wrapShellGameScreenSpecsShell({
  required AppEventBus bus,
  required bool autoSaveAvailable,
}) {
  // Colonial ShellScreen specialization via buildAppShell (Refs #4035).
  return buildAppShell(
    theme: AppThemes.colonial,
    navigatorKey: appNavigatorKey,
    overrides: [
      appEventBusProvider.overrideWith((ref) => bus),
      mainMenuAutoSaveAvailableProvider.overrideWith(
        (ref) => autoSaveAvailable,
      ),
    ],
    shellWrapper: (Widget app) => AppEventHandlerScope(child: app),
    child: const ShellScreen(),
  );
}

Widget wrapShellGameScreenSpecsGame({
  required AppEventBus bus,
  required Game game,
  required bool victory,
  bool calendarHalted = false,
  bool blocking = false,
  bool introShown = true,
}) {
  var activeGame = victory
      ? game.copyWith(
          victory: VictoryState(
            winnerPlayerId: game.players.first.id,
            type: VictoryType.military,
            turnNumber: 12,
          ),
        )
      : game;
  if (calendarHalted) {
    activeGame = activeGame.copyWith(calendarCampaignHalted: true);
  }
  return buildGameScreenHost(
    gamesBox: ShellGameScreenSpecsStubBox(),
    game: activeGame,
    mapViewData: null,
    width: 900,
    height: 700,
    navigatorKey: appNavigatorKey,
    introShownIds: introShown ? {activeGame.id} : <String>{},
    includeHomeFleetCargo: false,
    includeTreasury: false,
    gameService: shellGameScreenSpecsStubService,
    eventBus: bus,
    extraOverrides: [
      turnResolutionBlockingProvider.overrideWith(
        () => _StaticBlockingNotifier(blocking),
      ),
    ],
  );
}

class _StaticBlockingNotifier extends StateToggleNotifier {
  _StaticBlockingNotifier(this._initial) : super(false);
  final bool _initial;
  @override
  bool build() => _initial;
}

AppEventBus createShellGameScreenSpecsBus() => AppEventBus.create();

void expectVictoryOverlayOwnsAllNinePatchButtons(WidgetTester tester) {
  final allButtons = find.byType(CtNinePatchButton);
  final overlayButtons = find.descendant(
    of: find.byType(VictoryOverlay),
    matching: find.byType(CtNinePatchButton),
  );
  expect(
    tester.widgetList(allButtons).length,
    tester.widgetList(overlayButtons).length,
    reason: 'No top-right Next turn button when victory is set.',
  );
  expect(tester.widgetList(overlayButtons), isNotEmpty);
}

