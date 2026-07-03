import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

final TileMapResult _ironTileMap = singleTileMap(Resource.iron);
final TileMapResult _grainTileMap = singleTileMap(Resource.grain);

void main() {
  group('ResourceExtractor', () {
    for (final scenario in resourceExtractorMineralTownDevScenarios(
      ironTileMap: _ironTileMap,
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test('town-rule-only + non-port: townDevelopmentLevel does NOT cap yield', () {
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ];
      final resourceGrid = [
        [null, null, null],
        [null, Resource.grain, null],
        [null, null, null],
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
              townTileKey: 'oldWorld|p2|1|0',
              townDevelopmentLevel: 2,
            ),
          ],
        ),
        tileState: tileState,
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
        4,
        reason:
            'town-rule-only tile with non-port town; townDevelopmentLevel=2 must NOT cap '
            'yield of 4 (SPEC/game/extraction-and-improvements.md § Extraction formula)',
      );
    });
  });
}
