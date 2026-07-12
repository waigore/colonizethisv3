import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

/// Regression: battle defender may differ from province owner when the owner has
/// no combat units in-province (conflict_detection.dart). Ownership transfer must
/// use the pre-battle province owner, not [BattleContext.defenderFactionId].
void main() {
  runLabeledScenarioGroup(
    'resolveBattleContext province ownership transfer',
    combatResolverProvinceOwnerTransferScenarios(),
    (s) => s.run(),
  );
}
