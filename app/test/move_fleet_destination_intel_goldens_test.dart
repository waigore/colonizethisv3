// Widget goldens for Move fleet destination hostile gist on DLG30001 (Refs #4573).
// SPEC: SPEC/ui/move-fleet-dialog.md § Destination hostile-fleet gist.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'move_fleet_destination_intel_goldens_test_support.dart';
import 'move_fleet_destination_intel_test_support.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: sea-zone row shows hostile patrol gist (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelPatrolGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology();
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: moveFleetDestIntelFullVisibilityTiles(),
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
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Hostile patrol'), findsOneWidget);
      expect(find.text('Fleets unknown'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_patrol.png'),
      );
    },
  );

  testWidgets(
    'golden: sea-zone row shows hostile blockade gist (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelBlockadeGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology();
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: const {
          moveFleetDestIntelSeaTile: 'fogged',
        },
        hostileFleets: [
          buildHostileAtSeaFleet(
            id: 'enemy_b',
            mission: FleetMission.blockade,
          ),
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
      expect(find.text('Hostile blockade'), findsOneWidget);
      expect(find.text('Hostile patrol'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_blockade.png'),
      );
    },
  );

  testWidgets(
    'golden: sea-zone row shows hostile fleets count gist (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelCountGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology();
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: moveFleetDestIntelFullVisibilityTiles(),
        hostileFleets: [
          buildHostileAtSeaFleet(id: 'enemy_d', mission: FleetMission.defend),
          buildHostileAtSeaFleet(id: 'enemy_n', mission: FleetMission.none),
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
      expect(find.text('Hostile fleets: 2'), findsOneWidget);
      expect(find.text('Hostile patrol'), findsNothing);
      expect(find.text('Hostile blockade'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_count.png'),
      );
    },
  );

  testWidgets(
    'golden: sea-zone row shows Fleets unknown without playerView (Refs #4573)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('moveFleetDestIntelUnknownGolden');
      final topology = buildMoveFleetDestinationIntelGoldenTopology();
      final game = buildMoveFleetDestinationIntelGoldenGame(
        visibilityByTile: moveFleetDestIntelFullVisibilityTiles(),
        hostileFleets: [
          buildHostileAtSeaFleet(id: 'enemy_p', mission: FleetMission.patrol),
        ],
      );

      await pumpMoveFleetDestinationIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        topology: topology,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Fleets unknown'), findsOneWidget);
      expect(find.text('Hostile patrol'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_fleet_destination_intel_unknown.png'),
      );
    },
  );
}
