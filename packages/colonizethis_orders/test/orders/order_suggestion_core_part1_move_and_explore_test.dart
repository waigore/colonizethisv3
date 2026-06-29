import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('suggestMoveOrders only returns moves that pass validation', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow);

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p2': ['$ow|p2|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fogged',
          },
        },
      );

      final game = Game(id: 'g1', worldState: world, players: [player]);

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

      expect(suggestions.length, 1);
      expect(suggestions.first.unitId, 'u1');
      expect(suggestions.first.destinationTileKey, '$ow|p2|0|0');
    });

    test(
      'suggestMoveOrders throws when source province has unknown visibility',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'Test GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        // No visibility for p1: source province unknown → game raises.
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
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
        expect(
          () => suggestMoveOrders(view, game, topology, const Orders()),
          throwsStateError,
        );
      },
    );

    test(
      'move suggestions use unit locationProvinceId (tileKey-derived for civilians)',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'Test GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final p3 = Province(id: '$ow|p3', regionId: ow, ownerId: playerId);
        // Civilian in p2 by tileKey; provinceId can differ (e.g. legacy). Source = locationProvinceId = p2.
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p2|0|0',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2, p3], units: [unit]),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p3': ['$ow|p3|0|0'],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p2|0|0': 'fullyVisible',
              'oldWorld|p3|0|0': 'fogged',
            },
          },
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        // p2 adjacent to p3 only (so suggested moves are from p2 → p3, not from p1).
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
            TopologyNode(
              id: 'p3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestMoveOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(suggestions.length, 1);
        expect(suggestions.first.unitId, 'u1');
        expect(suggestions.first.destinationTileKey, '$ow|p3|0|0');
        // Move is from p2 (unit's location province), not p1. Unit with tileKey uses compound id.
        expect(view.ownUnitsById['u1']!.locationProvinceId, 'oldWorld|p2');
      },
    );

    test('no explore suggestion when province unknown', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      // No visibility: p1 unknown, so explore not suggested.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
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
      expect(suggestions.where((o) => o.target == kWorkTargetExplore), isEmpty);
    });

    test('suggestWorkOrders explore target uses kWorkTargetExplore', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const p1Id = '$ow|p1';
      const t0 = 'oldWorld|p1|0|0';
      const t1 = 'oldWorld|p1|1|0';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: p1Id, regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: p1Id,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {t0: 'fullyVisible', t1: 'unknown'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            p1Id: [t0, t1],
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
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
      final explore = suggestions.where((o) => o.target == kWorkTargetExplore);
      expect(explore, isNotEmpty);
    });

    test(
      'suggestWorkOrders explore aligns with partially revealed province cache scope',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const partialProvince = '$ow|p_partial';
        const fullyKnownProvince = '$ow|p_known';
        const partialKnownTile = 'oldWorld|p_partial|0|0';
        const partialUnknownTile = 'oldWorld|p_partial|1|0';
        const knownTile = 'oldWorld|p_known|0|0';

        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final explorer = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: partialProvince,
          tileKey: partialKnownTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: partialProvince, regionId: ow, ownerId: 'tribe1'),
              Province(id: fullyKnownProvince, regionId: ow, ownerId: 'tribe1'),
            ],
            units: [explorer],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              partialKnownTile: 'fogged',
              partialUnknownTile: 'unknown',
              knownTile: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              partialProvince: [partialKnownTile, partialUnknownTile],
              fullyKnownProvince: [knownTile],
            },
          },
        );
        final game = Game(
          id: 'g-cache-scope',
          worldState: world,
          players: [player],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
          // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
          overtureStates: const [
            OvertureState(
              gpId: playerId,
              targetId: 'tribe1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);

        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );

        final explore = suggestions.where(
          (o) => o.target == kWorkTargetExplore,
        );
        expect(explore, isNotEmpty);
        final exploreOrder = explore.first;
        expect(
          Unit.provinceIdFromTileKey(exploreOrder.targetTileKey),
          partialProvince,
        );
      },
    );
  });
}
