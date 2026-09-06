// Golden fixtures and pump helpers for diplomacy panel visual acceptance tests.
// Used by `diplomacy_panel_goldens_test.dart` (Refs #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'diplomacy_panel_goldens_game_fixtures.dart';
import 'diplomacy_panel_test_support.dart';
import 'golden_capture_harness.dart';

export 'diplomacy_panel_goldens_game_fixtures.dart';

Widget diplomacyPanelGoldenHost({
  required Game game,
  required Key boundaryKey,
  MapTopology topology = diplomacyPanelGoldenEmptyTopology,
  double width = 460,
  double height = 1000,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    child: SizedBox(
      width: width,
      height: height,
      child: DiplomacyPanel(
        game: game,
        humanPlayerId: 'gp1',
        topology: topology,
        currentOrders: const Orders(),
        bus: AppEventBus.create(),
      ),
    ),
  );
}

Future<void> pumpDiplomacyPanelGolden(
  WidgetTester tester, {
  required Game game,
  required Key boundaryKey,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  await configureGoldenSurface(tester, size: surface);
  await tester.pumpWidget(
    diplomacyPanelGoldenHost(
      game: game,
      boundaryKey: boundaryKey,
      width: width,
      height: height,
    ),
  );
  await pumpDiplomacyPanelBuilt(tester);
}

Future<void> runDiplomacyPanelGolden(
  WidgetTester tester, {
  required Game game,
  required String keyId,
  required String golden,
  required void Function(WidgetTester tester) pin,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  final boundaryKey = ValueKey<String>(keyId);
  await pumpDiplomacyPanelGolden(
    tester,
    game: game,
    boundaryKey: boundaryKey,
    surface: surface,
    width: width,
    height: height,
  );
  pin(tester);
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(golden),
  );
}
