import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('Great Power fall', () {
    test(
        'GP with lost original capital and no remaining port provinces forfeits and transfers provinces',
        () {
      const ow = 'oldWorld';

      // Province P1 was original capital (now owned by p2); P2 is inland and owned by p1.
      final provinces = [
        const Province(id: '$ow|P1', regionId: ow, ownerId: 'p2'),
        Province(
          id: '$ow|P2',
          regionId: ow,
          ownerId: 'p1',
          townTileKey: '$ow|P2|0|0',
        ),
      ];

      // Ports: only on P1, which is now owned by p2.
      final portsByProvinceSeaboard = {
        '$ow|P1|sea1': '$ow|P1|0|0',
      };

      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        oldWorld: RegionData(provinces: provinces),
        portsByProvinceSeaboard: portsByProvinceSeaboard,
        players: [
          const Player(
            id: 'p1',
            displayName: 'Attacker',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: '$ow|P1',
              x: 0,
              y: 0,
            ),
          ),
          const Player(
            id: 'p2',
            displayName: 'Conqueror',
            isHuman: true,
          ),
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
              id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      // No battles needed; state already reflects lost capital. Run resolveTurnForGame
      // to drive combat phase (which will run capital reassignment + GP fall).
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
      ));

      // All former p1 provinces should now belong to p2.
      for (final p in next.worldState.oldWorld.provinces) {
        expect(p.ownerId, 'p2');
      }
    });
  });
}

