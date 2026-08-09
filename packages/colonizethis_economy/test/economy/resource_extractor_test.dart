import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

final TileMapResult _grainTileMap = singleTileMap(Resource.grain);
final TileMapResult _ironTileMap = singleTileMap(Resource.iron);

void main() {
  group('ResourceExtractor', () {
    runLabeledScenarios(
      resourceExtractorConnectivityCapScenarios(grainTileMap: _grainTileMap),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );

    runLabeledScenarios(
      resourceExtractorMineralTownDevScenarios(
        ironTileMap: _ironTileMap,
        grainTileMap: _grainTileMap,
      ),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );

    runLabeledScenarios(resourceExtractorEmptyConnectivityScenarios(), (
      scenario,
    ) {
      runResourceExtractorScenario(scenario);
    }, labelOf: (s) => s.label);

    runLabeledScenarios(
      resourceExtractorSpecialCaseScenarios(grainTileMap: _grainTileMap),
      (scenario) {
        runResourceExtractorScenario(scenario);
      },
      labelOf: (s) => s.label,
    );
  });
}
