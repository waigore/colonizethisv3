// Fixtures and pump helpers for MoveFleetDialog tests (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'app_shell_harness.dart';

const String kMoveFleetHumanId = 'gp_move_dialog';
const String kMoveFleetOriginSea = 'sea_ow';
const String kMoveFleetSameRegionWarpSea = 'sea_local';
const String kMoveFleetSameRegionNonWarpSea = 'sea_plain';
const String kMoveFleetCrossRegionWarpSea = 'sea_nw';

Widget moveFleetOpenDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

T? Function() captureMoveFleetBusEvent<T extends AppEvent>(AppEventBus bus) {
  T? captured;
  addTearDown(bus.on<T>().listen((e) => captured = e).cancel);
  return () => captured;
}

TopologyNode moveFleetSeaNode(String id, String regionId) =>
    TopologyNode(id: id, regionId: regionId, type: TopologyNodeType.seaZone);

Game buildMoveFleetDialogGame() => Game(
  id: 'g_move_dialog',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'port_home',
          regionId: 'oldWorld',
          ownerId: kMoveFleetHumanId,
          displayName: 'Home Port',
        ),
      ],
    ),
    newWorld: const RegionData(),
    portsByProvinceSeaboard: const {
      'oldWorld|port_home|sea_local': 'oldWorld|port_home|0|0',
      'newWorld|port_nw|sea_nw': 'newWorld|port_nw|0|0',
    },
    seaZoneDisplayNameById: const {
      'oldWorld|sea_ow': 'Origin Sea',
      'oldWorld|sea_local': 'Warp OW Sea',
      'oldWorld|sea_plain': 'Plain OW Sea',
      'newWorld|sea_nw': 'Cross NW Sea',
    },
  ),
  players: const [
    Player(
      id: kMoveFleetHumanId,
      displayName: 'Move Dialog Tester',
      isHuman: true,
      capitalProvinceId: 'oldWorld|port_home',
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|port_home',
        x: 0,
        y: 0,
      ),
    ),
  ],
);

MapTopology buildMoveFleetDialogTopology() => MapTopology(
  nodes: [
    moveFleetSeaNode(kMoveFleetOriginSea, 'oldWorld'),
    moveFleetSeaNode(kMoveFleetSameRegionWarpSea, 'oldWorld'),
    moveFleetSeaNode(kMoveFleetSameRegionNonWarpSea, 'oldWorld'),
    moveFleetSeaNode(kMoveFleetCrossRegionWarpSea, 'newWorld'),
  ],
  edges: const [
    TopologyEdge(id1: kMoveFleetOriginSea, id2: kMoveFleetSameRegionWarpSea),
    TopologyEdge(id1: kMoveFleetOriginSea, id2: kMoveFleetSameRegionNonWarpSea),
    TopologyEdge(id1: kMoveFleetOriginSea, id2: kMoveFleetCrossRegionWarpSea),
    TopologyEdge(
      id1: kMoveFleetSameRegionWarpSea,
      id2: kMoveFleetCrossRegionWarpSea,
    ),
  ],
);

Fleet buildMoveFleetDialogFleet() => Fleet(
  id: 'f_move',
  ownerId: kMoveFleetHumanId,
  regionId: 'oldWorld',
  seaZoneId: kMoveFleetOriginSea,
  ships: [ShipInstance(id: 'ship_1', typeId: 'carrack')],
);

Future<void> openMoveFleetDialog(
  WidgetTester tester, {
  required AppEventBus bus,
  Game? game,
  MapTopology? topology,
  Fleet? fleet,
  String playerId = kMoveFleetHumanId,
}) async {
  final resolvedGame = game ?? buildMoveFleetDialogGame();
  final resolvedTopology = topology ?? buildMoveFleetDialogTopology();
  final resolvedFleet = fleet ?? buildMoveFleetDialogFleet();
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return moveFleetOpenDialogButton(() {
              showDialog<void>(
                context: context,
                builder: (_) => MoveFleetDialog(
                  game: resolvedGame,
                  topology: resolvedTopology,
                  humanPlayerId: playerId,
                  fleet: resolvedFleet,
                  bus: bus,
                ),
              );
            });
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
}
