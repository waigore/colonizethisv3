import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('fromPlayerView lists NW provinces reachable via sea and warp', () {
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
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
        ),
        newWorld: const RegionData(
          provinces: [
            Province(
              id: 'newWorld|colony',
              regionId: 'newWorld',
              ownerId: 'tribe1',
            ),
          ],
        ),
      ),
      players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe')],
    );
    final view = buildPlayerView(game, topology, 'gp1');
    final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);

    expect(snapshot.colonial.newWorldProvincesOwned, 0);
    expect(snapshot.colonial.invadableNewWorldProvinceIdsSorted, [
      'newWorld|colony',
    ]);
    expect(snapshot.colonial.invadableNewWorldProvinceIdsByDistance, [
      'newWorld|colony',
    ]);
    expect(snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted, ['tribe1']);
  });

  test('fromPlayerView orders invadable NW by adjacency distance ascending '
      '(Refs #2509 planColonialAcquisition)', () {
    // Two NW colonies are reachable through the same OW -> NW sea
    // bridge: `newWorld|near` shares a direct sea border with the
    // NW sea zone (distance 3), while `newWorld|far` requires
    // crossing an extra NW sea hop (distance 5). The lex-sorted
    // `invadableNewWorldProvinceIdsSorted` lists them
    // alphabetically -> `newWorld|far` first. The
    // distance-sorted `invadableNewWorldProvinceIdsByDistance`
    // surfaces `newWorld|near` first to satisfy the spec wording
    // "sorted by adjacency distance to owned territory".
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
          id: 'newWorld|nearSea',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 'newWorld|farSea',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 'newWorld|near',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'newWorld|far',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
        TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nearSea'),
        TopologyEdge(id1: 'newWorld|nearSea', id2: 'newWorld|near'),
        TopologyEdge(id1: 'newWorld|nearSea', id2: 'newWorld|farSea'),
        TopologyEdge(id1: 'newWorld|farSea', id2: 'newWorld|far'),
      ],
    );
    final game = Game(
      id: 'g-issue-2509-acquisition-distance',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
        ),
        newWorld: const RegionData(
          provinces: [
            Province(
              id: 'newWorld|near',
              regionId: 'newWorld',
              ownerId: 'tribe1',
            ),
            Province(
              id: 'newWorld|far',
              regionId: 'newWorld',
              ownerId: 'tribe2',
            ),
          ],
        ),
      ),
      players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
      tribes: const [
        Tribe(id: 'tribe1', displayName: 'T1'),
        Tribe(id: 'tribe2', displayName: 'T2'),
      ],
    );
    final view = buildPlayerView(game, topology, 'gp1');
    final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);

    expect(
      snapshot.colonial.invadableNewWorldProvinceIdsSorted,
      ['newWorld|far', 'newWorld|near'],
      reason:
          'lex-sorted field uses alphabetic order regardless of '
          'topology distance.',
    );
    expect(
      snapshot.colonial.invadableNewWorldProvinceIdsByDistance,
      ['newWorld|near', 'newWorld|far'],
      reason:
          'distance-sorted field puts newWorld|near (distance 3) '
          'before newWorld|far (distance 5).',
    );
  });

  test('fromPlayerView leaves invadableNewWorldProvinceIdsByDistance empty '
      'when no topology is supplied to AIWorldSnapshot.fromPlayerView', () {
    // The snapshot builder skips the BFS-distance computation when
    // no topology is passed (synthetic fixtures without map data
    // and the legacy call-sites that do not supply topology). This
    // pins the fall-back branch `planColonialAcquisition` relies
    // on: with the distance list empty, the planner reverts to
    // the lex-sorted invadable list.
    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: 'oldWorld|home',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    );
    final game = Game(
      id: 'g-issue-2509-no-topology',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
    );
    final view = buildPlayerView(game, topology, 'gp1');
    final snapshot = AIWorldSnapshot.fromPlayerView(view);

    expect(snapshot.colonial.invadableNewWorldProvinceIdsByDistance, isEmpty);
    expect(snapshot.colonial.invadableNewWorldProvinceIdsSorted, isEmpty);
  });
}
