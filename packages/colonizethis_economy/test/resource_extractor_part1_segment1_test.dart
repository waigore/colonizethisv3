import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);

void main() {
  group('ResourceExtractor', () {
    for (final scenario in resourceExtractorConnectivityCapScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test('effective extraction capped by player tech cap when improvement and '
        'transport are high', () {
      final tileMap = _grainTileMap;
      final tileState = tileStateFromSpecs(const [
        TileImprovementSpec('oldWorld|p1|0|0', improvement: 4, roadLevel: 4),
      ]);
      final game = resourceExtractorGame(tileState: tileState);
      final resultCap2 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
        techCapForPlayer: (_) => 2,
      );
      expect(resultCap2['pl1']!.land['grain'], 2);

      final resultCap3 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
        techCapForPlayer: (_) => 3,
      );
      expect(resultCap3['pl1']!.land['grain'], 3);
    });
  });
}
