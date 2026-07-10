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

    test(
      resourceExtractorPlayerTechCapScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        resourceExtractorPlayerTechCapScenario(grainTileMap: _grainTileMap),
      ),
    );

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

    for (final scenario in resourceExtractorEmptyConnectivityScenarios()) {
      test(scenario.label, () => runResourceExtractorScenario(scenario));
    }

    test(
      provinceMissingFromRegionScenario(grainTileMap: _grainTileMap).label,
      () => runResourceExtractorScenario(
        provinceMissingFromRegionScenario(grainTileMap: _grainTileMap),
      ),
    );

    test(
      capitalGrainBonusScenario().label,
      () => runResourceExtractorScenario(capitalGrainBonusScenario()),
    );

    for (final scenario in tileExtractionContributionScenarios(
      grainTileMap: _grainTileMap,
    )) {
      test(scenario.label, () => runTileExtractionContributionScenario(scenario));
    }
  });
}
