import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveArmyMoveDestinationProvinceId (#3448)',
    resolveArmyMoveDestinationProvinceIdScenarios(),
    (s) => s.run(),
  );
  runLabeledScenarioGroup(
    'unitsByProvinceIndex (#3448)',
    unitsByProvinceIndexScenarios(),
    (s) => s.run(),
  );
  runLabeledScenarioGroup(
    'provincesByIdIndex (#3448)',
    provincesByIdIndexScenarios(),
    (s) => s.run(),
  );
  runLabeledScenarioGroup(
    'PreCombatMovementIndex.build (#3448)',
    preCombatMovementIndexBuildScenarios(),
    (s) => s.run(),
  );
}
