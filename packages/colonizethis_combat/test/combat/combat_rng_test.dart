import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('combat_rng factories (#3448)', () {
    runLabeledScenarios(combatRngScenarios(), (s) => s.run());
    runLabeledScenarioGroup(
      'game-seeded factories',
      gameSeededCombatRngScenarios(),
      (s) => s.run(),
    );
  });
}
