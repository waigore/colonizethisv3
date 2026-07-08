import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'buildProvinceIndex',
    buildProvinceIndexScenarios(),
    runBuildProvinceIndexScenario,
  );

  runLabeledScenarioGroup(
    'collectPortTileKeys',
    collectPortTileKeysScenarios(),
    runCollectPortTileKeysScenario,
  );

  runLabeledScenarioGroup(
    'capitalFactionLookup',
    capitalFactionLookupScenarios(),
    runCapitalFactionLookupScenario,
  );
}
