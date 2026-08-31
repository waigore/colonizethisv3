// ProductionScreen 320 dp min-viewport pump helper (Refs #4680, #2870 S10).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/production/production_screen.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

const Size kProductionMinViewport = Size(kMinViewportWidth, 640);
const Size kProductionWideRegressionViewport = Size(1024, 768);

ShellPlayerContext productionGlobalObserveShellContext() =>
    ShellPlayerContext.globalObserve();

Future<void> pumpProductionScreenAtViewport(
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
      if (globalObserve)
        shellPlayerContextProvider.overrideWithValue(
          productionGlobalObserveShellContext(),
        ),
    ],
    child: ProductionScreen(
      game: game,
      player: player,
      attachGameToUiListener: false,
      panelTopologyOverride: const MapTopology(),
      panelTileMapByRegionOverride: null,
    ),
    settle: true,
  );
}
