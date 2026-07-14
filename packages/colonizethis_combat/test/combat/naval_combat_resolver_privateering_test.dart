import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

/// Privateering interception bonus (Slice B of #3470).
/// SPEC/program/naval-movement-resolution.md § Interception;
/// SPEC/game/tech-tree-naval.md (`privateering_companies`).
void main() {
  runLabeledScenarioGroup(
    'navalInterceptProbability privateering bonus',
    navalPrivateeringInterceptProbabilityScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'filterBattlesByInterception privateering wiring',
    filterBattlesByInterceptionPrivateeringScenarios(),
    (s) => s.run(),
  );
}
