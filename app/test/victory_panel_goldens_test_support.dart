// Victory panel golden harness helpers (Refs #4352).

import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'panel_fixtures/core.dart';
import 'victory_panel_test_support.dart';

const Size victoryPanelGoldenDesktopViewport = Size(900, 760);

RegionMapViewData victoryPanelGoldenSampleOldWorldRegion() =>
    sampleVictoryAnnotatedOldWorldRegion();

Game victoryPanelGoldenStandingsGame() {
  return buildPanelTestGame(
    players: [
      panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
      const Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    oldWorldProvinces: const [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
      Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp2'),
    ],
  );
}

Future<void> pumpVictoryPanelBodyGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  Size viewport = victoryPanelGoldenDesktopViewport,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    includeLocalizations: true,
    wrapInProviderScope: true,
    center: false,
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: SingleChildScrollView(
        child: VictoryScreenBody(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      ),
    ),
  );
}
