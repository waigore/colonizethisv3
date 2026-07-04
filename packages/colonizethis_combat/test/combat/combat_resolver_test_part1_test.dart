import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveEngagement', () {
    for (final scenario in combatResolverEngagementScenarios()) {
      test(scenario.label, () => runCombatResolverEngagementScenario(scenario));
    }
  });
}
