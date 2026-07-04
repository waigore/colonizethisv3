import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveQuickBattle', () {
    for (final scenario in resolveQuickBattleScenarios()) {
      test(scenario.label, () => runQuickBattleResolverScenario(scenario));
    }
  });
}
