/// Combat-style scenarios for siege Quick Battle: virtual emplaced guns absorb
/// defender-side damage before/during regiment losses; fort may downgrade when
/// all guns are destroyed. SPEC/game/quick-battle.md, SPEC/program/quick-battle-resolution.md.
library;
import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Quick Battle siege scenarios (emplaced targeting)', () {
    for (final scenario in quickBattleSiegeScenarios()) {
      test(scenario.label, () => runQuickBattleSiegeScenario(scenario));
    }
  });

  group('Quick Battle initiative scenarios', () {
    for (final scenario in quickBattleInitiativeScenarios()) {
      test(scenario.label, () => runQuickBattleSiegeScenario(scenario));
    }
  });
}
