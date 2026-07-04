import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('MutableEmplacedGun.fromInput', () {
    for (final scenario in mutableEmplacedGunFromInputScenarios()) {
      test(scenario.label, () => runQuickBattleEmplacedGunScenario(scenario));
    }
  });

  group('aliveGunStrengthSum', () {
    for (final scenario in aliveGunStrengthSumScenarios()) {
      test(scenario.label, () => runQuickBattleEmplacedGunScenario(scenario));
    }
  });

  group('sumAliveGunHp', () {
    for (final scenario in sumAliveGunHpScenarios()) {
      test(scenario.label, () => runQuickBattleEmplacedGunScenario(scenario));
    }
  });

  group('applyRoundRobinGunHpDamage', () {
    for (final scenario in applyRoundRobinGunHpDamageScenarios()) {
      test(scenario.label, () => runQuickBattleEmplacedGunScenario(scenario));
    }
  });
}
