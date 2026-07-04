import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveSeaBattle', () {
    for (final scenario in resolveSeaBattleScenarios()) {
      test(scenario.label, () => runNavalCombatResolutionScenario(scenario));
    }
  });

  group('applyNavalBattleResults', () {
    for (final scenario in applyNavalBattleResultsScenarios()) {
      test(scenario.label, () => runNavalCombatResolutionScenario(scenario));
    }
  });

  group('navalInterceptProbability', () {
    for (final scenario in navalInterceptProbabilityScenarios()) {
      test(scenario.label, () => runNavalCombatResolutionScenario(scenario));
    }
  });
}
