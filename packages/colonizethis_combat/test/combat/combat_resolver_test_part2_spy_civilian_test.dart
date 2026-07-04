import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveBattleContext Spy timer interaction', () {
    for (final scenario in combatResolverSpyCivilianScenarios()) {
      test(
        scenario.label,
        () => runCombatResolverSpyCivilianScenario(scenario),
      );
    }
  });
}
