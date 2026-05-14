import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show ProvinceId;

void main() {
  test(
    'multi-GP setup assigns one home fleet per GP with expected ship counts',
    () {
      final owNodes = <TopologyNode>[
        const TopologyNode(
          id: 'sea1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        for (var i = 1; i <= 8; i++)
          TopologyNode(
            id: 'p$i',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final owEdges = <TopologyEdge>[
        const TopologyEdge(id1: 'p1', id2: 'sea1'),
        const TopologyEdge(id1: 'p2', id2: 'sea1'),
        const TopologyEdge(id1: 'p8', id2: 'sea1'),
        for (var i = 1; i < 8; i++) TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
      ];
      final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
      final owTileMap = TileMapResult(
        width: 8,
        height: 2,
        grid: [
          [for (var i = 1; i <= 8; i++) 'p$i'],
          [for (var i = 1; i <= 8; i++) 'sea1'],
        ],
      );

      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
      );
      final nwTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['nw1'],
          ['nwSea'],
        ],
      );

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 8,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'home-fleet-index',
      );

      final startingShips = config.startingResources.initialNavalShips;
      expect(result.game.players.length, 2);

      for (final p in result.game.players) {
        final cap = p.capitalProvinceId;
        expect(cap, isNotNull);
        expect(
          ProvinceId.regionIdFrom(cap!),
          kRegionOldWorld,
          reason: 'home fleet merge path is OW-only',
        );
        final fid = homeFleetIdFor(p.id);
        final fleets = result.game.worldState.fleets
            .where((f) => f.id == fid)
            .toList();
        expect(fleets.length, 1, reason: 'single home fleet for ${p.id}');
        expect(
          fleets.single.ships.length,
          startingShips,
          reason: 'default ruleset starting naval ships',
        );
      }
    },
  );
}
