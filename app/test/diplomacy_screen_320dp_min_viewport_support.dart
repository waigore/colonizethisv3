// Shared 320 dp DiplomacyScreen pump (Refs #4720 Slice G).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

/// Minimum supported viewport — width [kMinViewportWidth] × 640 dp.
const Size kDiplomacyScreen320MinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel above every per-screen breakpoint.
const Size kDiplomacyScreen320WideViewport = Size(1024, 768);

/// Pumps [DiplomacyScreen] at [size] via [pumpAtMinViewport].
Future<void> pumpDiplomacyScreen320(
  WidgetTester tester, {
  required Size size,
  required Game game,
  required String humanPlayerId,
  bool globalObserve = false,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    overrides: [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      if (globalObserve)
        shellPlayerContextProvider.overrideWithValue(
          ShellPlayerContext.globalObserve(),
        ),
    ],
    child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
    settle: true,
  );
}
