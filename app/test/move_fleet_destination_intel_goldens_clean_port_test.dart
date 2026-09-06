// Golden pins for clean sea and owned-port move-fleet destination rows (Refs #4573).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'move_fleet_destination_intel_goldens_test_support.dart';
import 'move_fleet_destination_intel_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: clean sea-zone row shows no hostile gist (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelCleanGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology();
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: moveFleetDestIntelFullVisibilityTiles(),
      );
      final view = buildPlayerView(
        game,
        topology,
        moveFleetDestIntelHumanId,
      );

      await pumpMoveFleetDestinationIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Hostile Sea'), findsOneWidget);
      expect(find.text('Hostile patrol'), findsNothing);
      expect(find.text('Hostile blockade'), findsNothing);
      expect(find.textContaining('Hostile fleets:'), findsNothing);
      expect(find.text('Fleets unknown'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_clean.png'),
      );
    },
  );

  testWidgets(
    'golden: owned-port row has no hostile gist beside sea row (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelPortGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology(
        includeOwnedPort: true,
      );
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: moveFleetDestIntelFullVisibilityTiles(),
        includeOwnedPort: true,
        hostileFleets: [
          buildHostileAtSeaFleet(id: 'enemy_p', mission: FleetMission.patrol),
        ],
      );
      final view = buildPlayerView(
        game,
        topology,
        moveFleetDestIntelHumanId,
      );

      await pumpMoveFleetDestinationIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
        playerView: view,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Coast Port'), findsOneWidget);
      expect(find.text('Hostile patrol'), findsOneWidget);
      expect(find.text('Fleets unknown'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_port.png'),
      );
    },
  );
}
