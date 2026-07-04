import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('detectNavalConflicts', () {
    for (final scenario in detectNavalConflictsScenarios()) {
      test(scenario.label, () => runNavalCombatResolverScenario(scenario));
    }
  });

  group('normalizeNavalBattleSidesForAttacker', () {
    for (final scenario in normalizeNavalBattleSidesScenarios()) {
      test(scenario.label, () => runNavalCombatResolverScenario(scenario));
    }
  });

  group('navalStrength', () {
    for (final scenario in navalStrengthScenarios()) {
      test(scenario.label, () => runNavalCombatResolverScenario(scenario));
    }
  });
}
