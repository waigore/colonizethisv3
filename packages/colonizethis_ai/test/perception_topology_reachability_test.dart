import 'package:colonizethis_ai/src/perception/perception_topology.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('reachableNonOwnedProvinceIdsViaSeas crosses sea and warp', () {
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
        TopologyNode(
          id: 'newWorld|far',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
        TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
        TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
        TopologyEdge(id1: 'newWorld|colony', id2: 'newWorld|far'),
      ],
    );
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'oldWorld|home',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
          ],
        ),
        newWorld: const RegionData(
          provinces: [
            Province(
              id: 'newWorld|colony',
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
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      ],
      tribes: const [
        Tribe(id: 'tribe1', displayName: 'T1'),
        Tribe(id: 'tribe2', displayName: 'T2'),
      ],
    );
    final view = buildPlayerView(game, topology, 'gp1');
    final reachable = reachableNonOwnedProvinceIdsViaSeas(
      topology,
      {'oldWorld|home'},
      view,
      regionIdFilter: kNewWorldRegionId,
    );

    expect(reachable, {'newWorld|colony'});
    expect(reachable.contains('newWorld|far'), isFalse);
  });
}
