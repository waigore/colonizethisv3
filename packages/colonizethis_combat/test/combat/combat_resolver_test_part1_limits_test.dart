import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveEngagement',
    combatResolverLimitsScenarios(),
    (s) => s.run(),
  );
}
