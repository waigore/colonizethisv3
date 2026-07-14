import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'MutableEmplacedGun.fromInput',
    mutableEmplacedGunFromInputScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'aliveGunStrengthSum',
    aliveGunStrengthSumScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'sumAliveGunHp',
    sumAliveGunHpScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'applyRoundRobinGunHpDamage',
    applyRoundRobinGunHpDamageScenarios(),
    (s) => s.run(),
  );
}
