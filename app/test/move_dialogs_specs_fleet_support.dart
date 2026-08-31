// Fixtures and pump helpers for move-fleet dialog spec tests (Refs #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'move_dialogs_specs_test_support.dart';

const moveFleetSpecsPlayerId = 'gp_specs_fleet';
const moveFleetSpecsOriginSea = 'sea_origin';
const moveFleetSpecsAdjacentSea = 'sea_adjacent';
const moveFleetSpecsCrossSea = 'sea_cross';
const moveFleetSpecsCapitalProvince = 'oldWorld|p_capital_specs';

MapTopology moveFleetSpecsTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: moveFleetSpecsOriginSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: moveFleetSpecsAdjacentSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: moveFleetSpecsCrossSea,
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: moveFleetSpecsOriginSea, id2: moveFleetSpecsAdjacentSea),
      TopologyEdge(id1: moveFleetSpecsOriginSea, id2: moveFleetSpecsCrossSea),
    ],
  );
}

Game moveFleetSpecsGame() {
  return Game(
    id: 'g_specs_fleet',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: moveFleetSpecsCapitalProvince,
            regionId: 'oldWorld',
            ownerId: moveFleetSpecsPlayerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
      portsByProvinceSeaboard: const {
        'oldWorld|p_capital_specs|sea_origin':
            'oldWorld|p_capital_specs|0|0',
        'oldWorld|p_capital_specs|sea_adjacent':
            'oldWorld|p_capital_specs|0|0',
        'newWorld|p_cross|sea_cross': 'newWorld|p_cross|0|0',
      },
      seaZoneDisplayNameById: const {
        'oldWorld|sea_origin': 'Origin Sea',
        'oldWorld|sea_adjacent': 'Adjacent Sea',
        'newWorld|sea_cross': 'Cross Sea',
      },
    ),
    players: const [
      Player(
        id: moveFleetSpecsPlayerId,
        displayName: 'Specs Admiral',
        isHuman: true,
        capitalProvinceId: moveFleetSpecsCapitalProvince,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: moveFleetSpecsCapitalProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

Fleet moveFleetSpecsFleet() {
  return Fleet(
    id: 'fspecs',
    ownerId: moveFleetSpecsPlayerId,
    regionId: 'oldWorld',
    seaZoneId: moveFleetSpecsOriginSea,
    ships: const [ShipInstance(id: 'ship_specs', typeId: 'carrack')],
  );
}

Future<void> pumpMoveFleetSpecsDialog(
  WidgetTester tester, {
  required AppEventBus bus,
}) async {
  final game = moveFleetSpecsGame();
  final topology = moveFleetSpecsTopology();
  final fleet = moveFleetSpecsFleet();
  await tester.pumpWidget(
    moveDialogsSpecsFrameWithOpener(
      (context) => () {
        showDialog<void>(
          context: context,
          builder: (_) => MoveFleetDialog(
            game: game,
            topology: topology,
            humanPlayerId: moveFleetSpecsPlayerId,
            fleet: fleet,
            bus: bus,
          ),
        );
      },
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
