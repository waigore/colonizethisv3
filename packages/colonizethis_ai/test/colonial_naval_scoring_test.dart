import 'package:colonizethis_ai/src/planning/colonial_naval_scoring.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';

void main() {
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: 'oldWorld|home',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'oldWorld|owSea',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|nwSea',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'newWorld|colony',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
      TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
      TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
    ],
  );

  final colonial = ColonialSummary(
    invadableNewWorldProvinceIdsSorted: const ['newWorld|colony'],
    adjacentNewWorldOwnerFactionIdsSorted: const ['tribe1'],
  );

  test('prioritizes NW sea zones over Old World seas under colonial pressure', () {
    final ranked = sortNavalMovesForColonialPressure(
      [
        const NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'oldWorld|owSea',
        ),
        const NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'newWorld|nwSea',
        ),
      ],
      topology,
      colonial,
    );
    expect(ranked.first.destinationSeaZoneId, 'newWorld|nwSea');
    expect(
      colonialNavalMoveScore(ranked.first, topology, colonial),
      kColonialNavalMovePriorityNwSeaZoneScore,
    );
  });

  test('gateway Old World sea outscores unrelated seas', () {
    expect(
      colonialNavalMoveScore(
        const NavalMoveOrder(
          fleetId: 'f1',
          destinationSeaZoneId: 'oldWorld|owSea',
        ),
        topology,
        colonial,
      ),
      kColonialNavalMoveGatewaySeaZoneScore,
    );
  });
}
