import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);
final TileMapResult _ironTileMap = singleTileMap(Resource.iron);

void main() {
  group('ResourceExtractor', () {
    for (final scenario in resourceExtractorConnectivityCapScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    for (final scenario in resourceExtractorMineralTownDevScenarios(
      ironTileMap: _ironTileMap,
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    for (final scenario in resourceExtractorEmptyConnectivityScenarios()) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    for (final scenario in resourceExtractorSpecialCaseScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    for (final scenario in tileExtractionContributionScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runTileExtractionContributionScenario(scenario));
    }
  });
}
