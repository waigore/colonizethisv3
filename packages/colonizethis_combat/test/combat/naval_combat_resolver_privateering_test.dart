import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Privateering interception bonus (Slice B of #3470).
/// SPEC/program/naval-movement-resolution.md § Interception;
/// SPEC/game/tech-tree-naval.md (`privateering_companies`).
void main() {
  group('navalInterceptProbability privateering bonus', () {
    for (final scenario in navalPrivateeringInterceptProbabilityScenarios()) {
      test(scenario.label, () => runNavalCombatPrivateeringScenario(scenario));
    }
  });

  group('filterBattlesByInterception privateering wiring', () {
    for (final scenario in filterBattlesByInterceptionPrivateeringScenarios()) {
      test(scenario.label, () => runNavalCombatPrivateeringScenario(scenario));
    }
  });
}
