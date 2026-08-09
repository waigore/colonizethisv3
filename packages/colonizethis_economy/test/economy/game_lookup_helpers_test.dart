import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'buildProvinceIndex',
    buildProvinceIndexScenarios(),
    runBuildProvinceIndexScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'collectPortTileKeys',
    collectPortTileKeysScenarios(),
    runCollectPortTileKeysScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'capitalFactionLookup',
    capitalFactionLookupScenarios(),
    runCapitalFactionLookupScenario,
    labelOf: (s) => s.label,
  );
}
