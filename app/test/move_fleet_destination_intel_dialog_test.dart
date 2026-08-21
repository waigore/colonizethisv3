// Widget pins for DLG30001 destination hostile gist (Refs #4573).

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'move_fleet_destination_intel_test_support.dart';

Future<void> _openMoveFleetIntelDialog(
  WidgetTester tester, {
  required Game game,
  required MapTopology topology,
  required Fleet fleet,
  PlayerView? playerView,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => MoveFleetDialog(
                    game: game,
                    topology: topology,
                    humanPlayerId: moveFleetDestIntelHumanId,
                    fleet: fleet,
                    bus: AppEventBus.create(),
                    playerView: playerView,
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  const originSea = 'sea_origin';
  const destSea = moveFleetDestIntelSea;
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: destSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: originSea, id2: destSea)],
  );

  Game gameWithHostilePatrol() => buildMoveFleetDestinationIntelGame(
    visibilityByTile: const {
      moveFleetDestIntelSeaTile: 'fullyVisible',
    },
    fleets: [
      Fleet(
        id: 'f_self',
        ownerId: moveFleetDestIntelHumanId,
        regionId: 'oldWorld',
        seaZoneId: originSea,
        ships: const [ShipInstance(id: 'ss1', typeId: 'carrack')],
      ),
      buildHostileAtSeaFleet(id: 'enemy_p', mission: FleetMission.patrol),
    ],
  );

  testWidgets('sea-zone row shows hostile patrol gist', (tester) async {
    final game = gameWithHostilePatrol();
    final view = buildPlayerView(game, topology, moveFleetDestIntelHumanId);
    final fleet = game.worldState.fleets.firstWhere((f) => f.id == 'f_self');

    await _openMoveFleetIntelDialog(
      tester,
      game: game,
      topology: topology,
      fleet: fleet,
      playerView: view,
    );

    expect(find.text('Hostile patrol'), findsOneWidget);
    expect(find.text('Fleets unknown'), findsNothing);
  });

  testWidgets('sea-zone row shows Fleets unknown without playerView',
      (tester) async {
    final game = gameWithHostilePatrol();
    final fleet = game.worldState.fleets.firstWhere((f) => f.id == 'f_self');

    await _openMoveFleetIntelDialog(
      tester,
      game: game,
      topology: topology,
      fleet: fleet,
    );

    expect(find.text('Fleets unknown'), findsOneWidget);
    expect(find.text('Hostile patrol'), findsNothing);
  });
}
