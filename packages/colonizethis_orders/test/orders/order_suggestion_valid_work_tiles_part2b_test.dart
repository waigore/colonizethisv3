import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('suggestMoveOrders excludes moves to other Great Power provinces', () {
      const playerId = 'gp1';
      const otherGpId = 'gp2';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );
      final otherGp = const Player(
        id: otherGpId,
        displayName: 'Other GP',
        isHuman: false,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: otherGpId);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fullyVisible',
          },
        },
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherGp],
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

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        suggestions.where(
          (m) =>
              Unit.provinceIdFromTileKey(m.destinationTileKey) == 'oldWorld|p2',
        ),
        isEmpty,
      );
    });

    test(
      'suggestWorkOrders suggests steal_tech for Spy in foreign capital',
      () {
        const playerId = 'gp1';
        const otherGpId = 'gp2';
        const ow = 'oldWorld';

        final player = Player(
          id: playerId,
          displayName: 'GP1',
          isHuman: false,
          techUnlocked: {},
        );
        final otherGp = Player(
          id: otherGpId,
          displayName: 'GP2',
          isHuman: false,
          capitalProvinceId: '$ow|gp2_cap',
          techUnlocked: {'some_tech': true},
        );

        final spyProvince = Province(
          id: '$ow|spy_loc',
          regionId: ow,
          ownerId: playerId,
        );
        final otherGpCapital = Province(
          id: '$ow|gp2_cap',
          regionId: ow,
          ownerId: otherGpId,
        );
        final spy = Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: playerId,
          locationProvinceId: '$ow|spy_loc',
          tileKey: 'oldWorld|spy_loc|0|0',
        );

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [spyProvince, otherGpCapital],
            units: [spy],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|spy_loc|0|0': 'fullyVisible',
              'oldWorld|gp2_cap|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|spy_loc': ['oldWorld|spy_loc|0|0'],
              '$ow|gp2_cap': ['oldWorld|gp2_cap|0|0'],
            },
          },
        );

        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player, otherGp],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'spy_loc',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'gp2_cap',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );

        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where((o) => o.target == kWorkTargetStealTech),
          isNotEmpty,
        );
      },
    );
  });
}
