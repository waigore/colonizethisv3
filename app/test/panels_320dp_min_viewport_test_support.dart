// Shared 320 dp panel pumps (Refs #4352).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';
import 'production_panel_test_support.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-level pin file.
const Size kPanelsMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen breakpoint
/// so the same panel renders its wide layout. If a future refactor flips
/// the overflow contract upstream, the contrast with the 320 dp positive
/// pins keeps the regression signal honest. Mirrors the same pattern in
/// `mobile_320dp_min_viewport_test.dart`.
const Size kPanelsWideRegressionViewport = Size(1024, 768);

/// Pumps [child] at [size] under the running editorial-monocle theme.
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern used by `mobile_320dp_min_viewport_test.dart` and
/// `victory_overlay_narrow_test.dart`.
Future<void> pumpPanelsNarrow(
  WidgetTester tester,
  Widget child, {
  required Size size,
  bool settle = true,
}) async {
  if (settle) {
    await pumpAtMinViewport(
      tester,
      size: size,
      child: Scaffold(body: child),
      settle: true,
    );
    return;
  }
  // DiplomacyPanel's hover-aware row chrome animates the border color via
  // `AnimatedContainer`; `pumpAndSettle` would block on that animation.
  // The harness pumps one frame; a second short timed pump lays out the
  // body without entering the animation steady-state loop.
  await pumpAtMinViewport(
    tester,
    size: size,
    child: Scaffold(body: child),
  );
  await tester.pump(const Duration(milliseconds: 16));
}

Widget buildPanelsProductionPanel(Player player) {
  return ProductionPanel(
    game: productionPanelTestGameFor(player),
    player: player,
    desiredOutputByRecipe: const <String, int>{},
    netDeltasByCommodity: const <String, int>{},
    labourReadiness: labourReadinessForPlayer(player),
    forcesFeeding: forcesFeedingForPlayer(player),
    onDesiredOutputChanged: (_) {},
  );
}

Widget buildPanelsDiplomacyPanel({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
}) {
  return DiplomacyPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    topology: topology,
    currentOrders: const Orders(),
    bus: AppEventBus.create(),
  );
}

/// Mirrors [TechnologyScreen] `_SlotsBody`: scroll host + panel so the 320 dp
/// pin exercises the same vertical-scroll contract as production.
Widget buildPanelsTechnologySlotsBody({
  required Game game,
  required Player player,
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: TechnologyPanel(game: game, player: player),
  );
}
