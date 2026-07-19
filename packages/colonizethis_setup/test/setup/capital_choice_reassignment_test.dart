// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

void main() {
  group('CapitalChoice reassignment', () {
    test(
      'setCapitalForReassignment updates player capital only; no port/road changes',
      () {
        final game = TestFixtures.minimalGame(
          id: 'g1',
          turnNumber: 1,
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
              ),
            ],
          ),
          portsByProvinceSeaboard: const {
            'oldWorld|p1|sea1': 'oldWorld|p1|0|0',
          },
          players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        );
        final next = setCapitalForReassignment(
          game: game,
          playerId: 'pl1',
          provinceId: 'oldWorld|p1',
          tile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
        );
        expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
        expect(next.players.single.capitalTile!.x, 1);
        expect(next.players.single.capitalTile!.y, 1);
        expect(
          next.worldState.portsByProvinceSeaboard,
          game.worldState.portsByProvinceSeaboard,
        );
        expect(next.worldState.tileState, game.worldState.tileState);
      },
    );

    test(
      'pickCapitalProvinceIdForReassignment prefers seaboard by sorted id',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pA',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'pB',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'pA', id2: 'sea1')],
        );
        final id = pickCapitalProvinceIdForReassignment([
          'oldWorld|pB',
          'oldWorld|pA',
        ], topology);
        expect(id, 'oldWorld|pA');
      },
    );

    test('pickCapitalProvinceIdForReassignment inland when no seaboard', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'pA',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'pB',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final id = pickCapitalProvinceIdForReassignment([
        'oldWorld|pB',
        'oldWorld|pA',
      ], topology);
      expect(id, 'oldWorld|pA');
    });
  });
}
