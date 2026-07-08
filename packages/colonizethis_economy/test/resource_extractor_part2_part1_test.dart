import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);

void main() {
  group('ResourceExtractor', () {
    test(
      townRulePortCapScenario().label,
      () => runResourceExtractorScenario(townRulePortCapScenario()),
    );

    test(
      overseasExtractionScenario().label,
      () => runResourceExtractorScenario(overseasExtractionScenario()),
    );

    test(
      blockadedOverseasPortScenario().label,
      () => runResourceExtractorScenario(blockadedOverseasPortScenario()),
    );

    test(
      pathTransportCapScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        pathTransportCapScenario(grainTileMap: _grainTileMap),
      ),
    );
  });
}
