// Shared 320 dp GameSideMenu pump (Refs #4734 Slice H).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'min_viewport_harness.dart';

const Size kGameSideMenu320MinViewport = Size(kMinViewportWidth, 640);
const Size kGameSideMenu320WideViewport = Size(1024, 768);

Future<void> pumpGameSideMenu320(
  WidgetTester tester, {
  required Size size,
  required Box<dynamic> gamesBox,
  required Game game,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    overrides: [
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
    ],
    child: AppEventHandlerScope(
      child: Scaffold(
        body: Stack(
          children: [GameSideMenu(sideMenuOpen: true, onClose: () {})],
        ),
      ),
    ),
    settle: true,
  );
}
