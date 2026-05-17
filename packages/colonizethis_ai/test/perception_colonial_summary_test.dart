import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('fromPlayerView lists adjacent New World tribe provinces as invadable', () {
    const topology = MapTopology(
      nodes: [
        TopologyNode(id: 'oldWorld|home', regionId: 'oldWorld', type: TopologyNodeType.province),
        TopologyNode(id: 'newWorld|colony', regionId: 'newWorld', type: TopologyNodeType.province),
      ],
      edges: [
        TopologyEdge(id1: 'oldWorld|home', id2: 'newWorld|colony'),
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
          ],
        ),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      ],
      tribes: const [
        Tribe(id: 'tribe1', displayName: 'Tribe'),
      ],
    );
    final view = buildPlayerView(game, topology, 'gp1');
    final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);

    expect(snapshot.colonial.newWorldProvincesOwned, 0);
    expect(
      snapshot.colonial.invadableNewWorldProvinceIdsSorted,
      ['newWorld|colony'],
    );
    expect(
      snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted,
      ['tribe1'],
    );
  });
}
