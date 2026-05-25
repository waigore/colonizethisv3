import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'planner_test_helpers.dart';

void main() {
  group('runDomainPlanners', () {
    test('returns empty orders when suggestion API returns no candidates', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        turnSeed: 999,
      );

      expect(orders.moveOrdersByPlayerId.isEmpty, isTrue);
      expect(orders.workOrdersByPlayerId.isEmpty, isTrue);
      expect(orders.buildUnitOrdersByPlayerId.isEmpty, isTrue);
      // Research planner may still suggest orders when candidates exist (e.g. default tech).
      expect(orders, isNotNull);
    });

    test('can produce move orders when topology and visibility allow', () {
      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: null),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'explorer',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(provinces: [], units: []),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p2|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': ['oldWorld|p1|0|0'],
              'oldWorld|p2': ['oldWorld|p2|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        turnSeed: 100,
      );

      expect(orders, isNotNull);
      // Move planner may add moves when weight >= 20 and candidates exist.
      expect(orders.moveOrdersByPlayerId['gp1'] != null, isTrue);
    });

    test('DefaultOrderSuggestionAPI can add army move for non-home army', () {
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const nw = 'newWorld|col';
      final game = Game(
        id: 'g_army_dom',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'gp1',
                locationProvinceId: p1,
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [Province(id: nw, regionId: 'newWorld', ownerId: 'gp1')],
          ),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
            Army(
              id: 'field_a',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|cap|0|0': 'fullyVisible',
              'oldWorld|p1|0|0': 'fullyVisible',
              'newWorld|col|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: [cap],
              p1: ['oldWorld|p1|0|0'],
            },
            'newWorld': {
              nw: ['newWorld|col|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'victoria',
            capitalProvinceId: cap,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: cap,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: p1,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: nw,
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        turnSeed: 77,
        primaryGoal: StrategicGoal.conquer,
      );

      expect(orders.armyMoveOrdersByPlayerId['gp1'], isNotNull);
      expect(orders.armyMoveOrdersByPlayerId['gp1']!, isNotEmpty);
    });
  });
}
