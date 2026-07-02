import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);

void main() {
  group('ResourceExtractor', () {
    test('town-rule-only + port: townDevelopmentLevel DOES cap yield', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p2'],
      ];
      final resourceGrid = [
        [null, null],
        [null, Resource.grain],
      ];
      final tileMap = tileMapFromGrids(grid: grid, resourceGrid: resourceGrid);
      const cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 1),
        TileImprovementSpec('oldWorld|p2|1|1', improvement: 4),
      ]);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p1|0|0',
              townDevelopmentLevel: 4,
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p2|0|1',
              townDevelopmentLevel: 2,
            ),
          ],
        ),
        tileState: tileState,
        portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|1'},
        players: [player],
      );
      const tileKey = 'oldWorld|p2|1|1';
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor(
          {tileKey},
          pathTransportCap: {tileKey: 4},
        ),
        techCapForPlayer: (_) => 4,
      );
      expect(
        result['pl1']!.land['grain'],
        2,
        reason:
            'town-rule-only tile with port town; townDevelopmentLevel=2 caps yield to 2 '
            '(SPEC/game/extraction-and-improvements.md § Extraction formula)',
      );
    });

    test(
      overseasExtractionScenario().label,
      () => runResourceExtractorScenario(overseasExtractionScenario()),
    );

    test(
      'blockaded overseas port: connectivity excludes tile so overseas extraction zero',
      () {
        final oldGrid = [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ];
        final newGrid = [
          ['n1', 'n1'],
          ['n1', 'n1'],
        ];
        final tileMapOw = TileMapResult(
          width: 2,
          height: 2,
          grid: oldGrid,
          resourceGrid: [
            [null, null],
            [null, null],
          ],
        );
        final tileMapNw = TileMapResult(
          width: 2,
          height: 2,
          grid: newGrid,
          resourceGrid: [
            [Resource.sugarCane, Resource.sugarCane],
            [null, null],
          ],
        );
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'n1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'n1', id2: 'sea2'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        const ow = 'oldWorld', nw = 'newWorld';
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = tileStateFromSpecs(const [
          TileImprovementSpec('newWorld|n1|0|0', improvement: 1, roadLevel: 4),
          TileImprovementSpec('newWorld|n1|1|0', improvement: 1, roadLevel: 4),
          TileImprovementSpec('oldWorld|p1|0|0', roadLevel: 4),
        ]);
        final ports = {
          '$ow|p1|sea1': 'oldWorld|p1|0|0',
          '$nw|n1|sea2': 'newWorld|n1|0|0',
        };
        final game = TestFixtures.minimalGame(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          oldWorld: RegionData(
            provinces: [
              Province(
                id: '$ow|p1',
                regionId: ow,
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(
                id: '$nw|n1',
                regionId: nw,
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          tileState: tileState,
          portsByProvinceSeaboard: ports,
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final connectivityBlockaded = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          topology: topology,
          blockadedPortProvincesByPlayerId: {
            'pl1': {'newWorld|n1'},
          },
        );
        final resultBlockaded = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          connectivityResult: connectivityBlockaded,
          techCapForPlayer: (_) => 4,
        );
        expect(resultBlockaded['pl1']!.overseas, isEmpty);
        expect(resultBlockaded['pl1']!.land, isEmpty);

        final connectivityOpen = resolveConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          topology: topology,
        );
        final resultOpen = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMapOw, 'newWorld': tileMapNw},
          connectivityResult: connectivityOpen,
          techCapForPlayer: (_) => 4,
        );
        expect(resultOpen['pl1']!.overseas['sugarCane'] ?? 0, greaterThan(0));
      },
    );

    test(
      pathTransportCapScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        pathTransportCapScenario(grainTileMap: _grainTileMap),
      ),
    );
  });
}
