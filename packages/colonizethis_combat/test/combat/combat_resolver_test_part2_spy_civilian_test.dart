import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveBattleContext Spy timer interaction',
    combatResolverSpyCivilianScenarios(),
    (s) => s.run(),
  );
}
