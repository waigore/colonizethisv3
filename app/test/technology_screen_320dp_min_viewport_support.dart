// Shared 320 dp TechnologyScreen pump (Refs #4720 Slice G).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

/// Minimum supported viewport — width [kMinViewportWidth] × 640 dp.
const Size kTechnologyScreen320MinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel above every per-screen breakpoint.
const Size kTechnologyScreen320WideViewport = Size(1024, 768);

/// Pumps [TechnologyScreen] at [size] via [pumpAtMinViewport].
Future<void> pumpTechnologyScreen320(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required Player player,
  bool globalObserve = false,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    overrides: [
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
          ShellPlayerContext.globalObserve(),
        ),
    ],
    child: TechnologyScreen(game: game, player: player),
  );
}
