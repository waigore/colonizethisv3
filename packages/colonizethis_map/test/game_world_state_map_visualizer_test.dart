import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:image/image.dart' as img;

void main() {
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
      TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );

  final smallResult = TileMapResult(
    width: 2,
    height: 2,
    grid: [
      ['p1', 's1'],
      ['s1', 's1'],
    ],
  );

  group('renderSingleRegionGameStateMapToPng', () {
    test('returns non-empty PNG with default faction colors', () {
      final bytes = renderSingleRegionGameStateMapToPng(
        result: smallResult,
        topology: topology,
        ownerByProvinceId: {'oldWorld|p1': 'gp1'},
        capitalTiles: [],
        cellSize: 8,
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 2 * 8);
      expect(decoded.height, greaterThanOrEqualTo(2 * 8));
    });

    test('with factionColorsOverride and capital and port tiles', () {
      final bytes = renderSingleRegionGameStateMapToPng(
        result: smallResult,
        topology: topology,
        ownerByProvinceId: {'oldWorld|p1': 'gp1'},
        capitalTiles: [
          (factionId: 'gp1', displayName: 'GP1', x: 0, y: 0),
        ],
        portTiles: [(x: 0, y: 0)],
        cellSize: 8,
        factionColorsOverride: {'gp1': (100, 100, 100)},
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.height, greaterThan(2 * 8));
    });
  });

  group('renderInitGameMapToPng', () {
    test('returns non-empty PNG for minimal game', () {
      final owMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'OW P1',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(
                id: 'newWorld|p1',
                regionId: 'newWorld',
                displayName: 'NW P1',
              ),
            ],
            units: const [],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        ],
        minorNations: const [],
        tribes: const [],
      );

      final bytes = renderInitGameMapToPng(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
    });
  });

  group('renderInitGameMapToPngFromViewData', () {
    test('returns non-empty PNG for ownership and geographic mode', () {
      final owMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final nwMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 's1'],
          ['s1', 's1'],
        ],
      );
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 's1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
            ],
            units: const [],
          ),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'newWorld|p1', regionId: 'newWorld'),
            ],
            units: const [],
          ),
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        minorNations: const [],
        tribes: const [],
      );

      final viewData = buildInitGameMapViewData(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );

      final bytesOwnership = renderInitGameMapToPngFromViewData(
        viewData: viewData,
        geographicMode: false,
      );
      expect(bytesOwnership, isNotEmpty);
      expect(img.decodeImage(bytesOwnership), isNotNull);

      final bytesGeographic = renderInitGameMapToPngFromViewData(
        viewData: viewData,
        geographicMode: true,
      );
      expect(bytesGeographic, isNotEmpty);
      expect(img.decodeImage(bytesGeographic), isNotNull);
    });
  });
}
