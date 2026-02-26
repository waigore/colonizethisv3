import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ResourceExtractor', () {
    test('stub connectivity: land totals and tech cap applied', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.grain, Resource.timber],
        [Resource.iron, null],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 3)
          .setImprovement('oldWorld|p1|1|0', 2)
          .setImprovement('oldWorld|p1|0|1', 4)
          .setRoadLevel('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final connectivity = {
        'pl1': ConnectivityResult(
          connected: {
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
            'oldWorld|p1|0|1',
          },
        ),
      };
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivity,
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1'], isNotNull);
      final tot = result['pl1']!;
      expect(tot.overseas, isEmpty);
      expect(tot.land['grain'], 2);
      expect(tot.land['timber'], 1);
      expect(tot.land['iron'], isNull);
    });

    test('effective extraction capped by transport level', () {
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.grain]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('extracts wool and copper when present on tile map', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.wool, Resource.copper],
        [Resource.timber, Resource.iron],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p1|1|0', 1)
          .setImprovement('oldWorld|p1|0|1', 1)
          .setImprovement('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 1)
          .setRoadLevel('oldWorld|p1|1|1', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final connectedTiles = {'oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|0|1', 'oldWorld|p1|1|1'};
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
          playerProspectedTiles: {'pl1': connectedTiles},
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {'pl1': ConnectivityResult(connected: connectedTiles)},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['wool'], 1);
      expect(result['pl1']!.land['copper'], 1);
      expect(result['pl1']!.land['timber'], 1);
      expect(result['pl1']!.land['iron'], 1);
    });

    test('mineral tiles without prospected are excluded from extraction', () {
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.iron]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], isNull);
      expect(result['pl1']!.land, isEmpty);
    });

    test('mineral from prospected tile counts in land', () {
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.iron]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
          playerProspectedTiles: {'pl1': {'oldWorld|p1|0|0'}},
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], 2);
    });

    test('effective extraction capped by province townDevelopmentLevel', () {
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.grain]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 4);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1', townDevelopmentLevel: 1),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('overseas totals when connected tile in different region', () {
      final gridNw = [['n1']];
      final tileMapNw = TileMapResult(
        width: 1,
        height: 1,
        grid: gridNw,
        resourceGrid: [[Resource.sugarCane]],
      );
      final tileState = TileMapState()
          .setImprovement('newWorld|n1|0|0', 1)
          .setRoadLevel('newWorld|n1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: RegionData(provinces: [
            Province(id: 'n1', regionId: 'newWorld', ownerId: 'pl1'),
          ]),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': TileMapResult(width: 1, height: 1, grid: [['p1']], resourceGrid: [[null]]), 'newWorld': tileMapNw},
        connectivityResult: {'pl1': ConnectivityResult(connected: {'newWorld|n1|0|0'})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.overseas['sugarCane'], 1);
      expect(result['pl1']!.land, isEmpty);
    });

    test('effective yield capped by min transport level along path to capital', () {
      // SPEC: effective yield = min(production, tech cap, town dev, min transport along path).
      // When pathTransportCap is provided, it caps yield (e.g. path with road-1 segment → cap 1).
      final grid = [['p1']];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [[Resource.grain]],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 3)
          .setRoadLevel('oldWorld|p1|0|0', 3);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'Spain',
            isHuman: true,
            capitalProvinceId: 'p1',
            capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
          ),
        ],
      );
      final connectivity = resolveConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: MapTopology(
          nodes: [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
          edges: [],
        ),
      );
      expect(connectivity['pl1']!.pathTransportCap['oldWorld|p1|0|0'], 3);
      final resultWithPathCap = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {'oldWorld|p1|0|0'},
            pathTransportCap: {'oldWorld|p1|0|0': 1},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(resultWithPathCap['pl1']!.land['grain'], 1);
    });

    test('returns empty ExtractionTotals when player has no connected tiles', () {
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'p1',
        capitalTile: CapitalTile(regionId: 'oldWorld', provinceId: 'p1', x: 0, y: 0),
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: 'p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: const {},
        connectivityResult: {'pl1': ConnectivityResult(connected: {})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land, isEmpty);
      expect(result['pl1']!.overseas, isEmpty);
    });
  });
}
