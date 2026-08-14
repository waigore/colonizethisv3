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

({Game game, MapTopology topology, Fleet fleet, String playerId})
buildMoveFleetNwFixture() {
  const nwHumanId = 'gp_move_dialog_nw';
  const nwOriginSea = 'sea_nw_origin';
  const sameRegionAdjacentSea = 'sea_nw_local';
  const crossRegionAdjacentSea = 'sea_ow_cross';
  return (
    playerId: nwHumanId,
    game: const Game(
      id: 'g_move_dialog_nw',
      worldState: WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
        seaZoneDisplayNameById: {
          'newWorld|sea_nw_origin': 'Origin NW Sea',
          'newWorld|sea_nw_local': 'Adjacent NW Sea',
          'oldWorld|sea_ow_cross': 'Cross OW Sea',
        },
      ),
      players: [
        Player(
          id: nwHumanId,
          displayName: 'Move Dialog Tester NW',
          isHuman: true,
          capitalProvinceId: 'newWorld|port_home_nw',
          capitalTile: CapitalTile(
            regionId: 'newWorld',
            provinceId: 'newWorld|port_home_nw',
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    topology: MapTopology(
      nodes: [
        moveFleetSeaNode(nwOriginSea, 'newWorld'),
        moveFleetSeaNode(sameRegionAdjacentSea, 'newWorld'),
        moveFleetSeaNode(crossRegionAdjacentSea, 'oldWorld'),
      ],
      edges: const [
        TopologyEdge(id1: nwOriginSea, id2: sameRegionAdjacentSea),
        TopologyEdge(id1: nwOriginSea, id2: crossRegionAdjacentSea),
      ],
    ),
    fleet: Fleet(
      id: 'f_move_nw',
      ownerId: nwHumanId,
      regionId: 'newWorld',
      seaZoneId: nwOriginSea,
      ships: [ShipInstance(id: 'ship_1', typeId: 'carrack')],
    ),
  );
}

({Game game, MapTopology topology, Fleet fleet}) buildMoveFleetInPortFixture() {
  const ow = 'oldWorld';
  const localCap = 'port_cap';
  final fullCap = '$ow|$localCap';
  return (
    topology: MapTopology(
      nodes: [
        TopologyNode(
          id: fullCap,
          regionId: ow,
          type: TopologyNodeType.province,
        ),
        moveFleetSeaNode('$ow|sea1', ow),
        moveFleetSeaNode('$ow|sea2', ow),
      ],
      edges: [
        TopologyEdge(id1: fullCap, id2: '$ow|sea1'),
        TopologyEdge(id1: fullCap, id2: '$ow|sea2'),
        TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
      ],
    ),
    game: Game(
      id: 'g_move_dialog_in_port',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: fullCap,
              regionId: ow,
              ownerId: kMoveFleetHumanId,
              displayName: 'Seabound Capital',
            ),
          ],
        ),
        newWorld: const RegionData(),
        seaZoneDisplayNameById: const {
          'oldWorld|sea1': 'First Sea',
          'oldWorld|sea2': 'Second Sea',
        },
      ),
      players: [
        Player(
          id: kMoveFleetHumanId,
          displayName: 'Move Dialog Tester',
          isHuman: true,
          capitalProvinceId: fullCap,
          capitalTile: CapitalTile(
            regionId: ow,
            provinceId: fullCap,
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    fleet: Fleet(
      id: 'f_in_port',
      ownerId: kMoveFleetHumanId,
      regionId: ow,
      inPortAtProvinceId: fullCap,
      ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
    ),
  );
}

({Game game, MapTopology topology, Fleet fleet, String playerId})
buildMoveFleetMixFixture() {
  const mixHumanId = 'gp_mix';
  const seaA = 'sea_a';
  const seaB = 'sea_b';
  const coastProv = 'coast_p';
  return (
    playerId: mixHumanId,
    game: Game(
      id: 'g_mix',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            const Province(
              id: 'oldWorld|inland_cap',
              regionId: 'oldWorld',
              ownerId: mixHumanId,
              displayName: 'Inland Capital',
            ),
            Province(
              id: 'oldWorld|$coastProv',
              regionId: 'oldWorld',
              ownerId: mixHumanId,
              displayName: 'Coastal Province',
            ),
          ],
        ),
        newWorld: const RegionData(),
        seaZoneDisplayNameById: {
          'oldWorld|$seaA': 'Alpha Sea',
          'oldWorld|$seaB': 'Beta Sea',
        },
      ),
      players: const [
        Player(
          id: mixHumanId,
          displayName: 'T',
          isHuman: true,
          capitalProvinceId: 'oldWorld|inland_cap',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|inland_cap',
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    topology: MapTopology(
      nodes: [
        moveFleetSeaNode(seaA, 'oldWorld'),
        moveFleetSeaNode(seaB, 'oldWorld'),
        const TopologyNode(
          id: coastProv,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [
        TopologyEdge(id1: seaA, id2: coastProv),
        TopologyEdge(id1: seaA, id2: seaB),
      ],
    ),
    fleet: Fleet(
      id: 'f_mix',
      ownerId: mixHumanId,
      regionId: 'oldWorld',
      seaZoneId: seaA,
      ships: [ShipInstance(id: 's1', typeId: 'carrack')],
    ),
  );
}

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
