// Shared 320 dp GameScreen pump (Refs #4720 Slice G).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'min_viewport_harness.dart';

/// Minimum supported viewport — width [kMinViewportWidth] × 640 dp.
const Size kGameScreen320MinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel above every per-screen breakpoint.
const Size kGameScreen320WideViewport = Size(1024, 768);

/// Pumps the live [GameScreen] at [size] under editorial-monocle.
/// Single `tester.pump()` (no settle) — Flame tickers never settle.
Future<void> pumpGameScreen320(
  WidgetTester tester, {
  required Size size,
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData mapViewData,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    overrides: buildGameScreenShellOverrides(
      gamesBox: gamesBox,
      game: game,
      mapViewData: mapViewData,
    ),
    navigatorKey: appNavigatorKey,
    child: AppEventHandlerScope(child: const GameScreen()),
  );
}
