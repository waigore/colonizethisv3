import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('buildQuickBattleInput', () {
    for (final scenario in quickBattleBuildSiegeScenarios().take(2)) {
      test(scenario.label, () => runQuickBattleBuildSiegeScenario(scenario));
    }
  });

  group('siege virtual emplaced guns (COL-151)', () {
    for (final scenario in quickBattleBuildSiegeScenarios().skip(2)) {
      test(scenario.label, () => runQuickBattleBuildSiegeScenario(scenario));
    }
  });
}
