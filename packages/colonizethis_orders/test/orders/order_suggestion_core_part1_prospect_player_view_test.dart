import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('no prospect suggestion when province not at least fogged', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: 'tribe1');
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      // Province tiles unknown only — prospect requires fogged or better.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'unknown'},
        },
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
      );
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
      expect(
        suggestions.where((o) => o.target == kWorkTargetProspect),
        isEmpty,
      );
    });

    test('prospect suggestion when province fogged and tiles in province', () {
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
      const tileKey = 'oldWorld|p1|0|0';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fogged'},
        },
        resourceByTileKey: const {tileKey: 'iron'},
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileKey],
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
      expect(
        suggestions.where((o) => o.target == kWorkTargetProspect),
        isNotEmpty,
      );
      expect(
        suggestions
            .firstWhere((o) => o.target == kWorkTargetProspect)
            .targetTileKey,
        tileKey,
      );
    });

    test(
      'PlayerView.provincesById matches allProvinces for prospect iteration order',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = const Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: 'minor1');
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p2, p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {'oldWorld|p1|0|0': 'fogged'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': const ['oldWorld|p1|0|0'],
              '$ow|p2': const ['oldWorld|p2|0|0'],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
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
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final fromAll = allProvinces(game.worldState).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        final fromView = view.provincesById.values.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        expect(fromView.length, fromAll.length);
        expect(
          fromView.map((p) => p.id).toList(),
          fromAll.map((p) => p.id).toList(),
        );
      },
    );
  });
}
