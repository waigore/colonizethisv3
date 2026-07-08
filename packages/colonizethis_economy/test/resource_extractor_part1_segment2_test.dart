import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

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

    test(
      townRuleNonPortNoCapScenario().label,
      () => runResourceExtractorScenario(townRuleNonPortNoCapScenario()),
    );
  });
}
