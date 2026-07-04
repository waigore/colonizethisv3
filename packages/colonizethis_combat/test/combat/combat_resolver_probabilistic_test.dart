import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveEngagementProbabilistic', () {
    for (final scenario in combatResolverProbabilisticScenarios()) {
      test(
        scenario.label,
        () => runCombatResolverProbabilisticScenario(scenario),
      );
    }
  });
}
