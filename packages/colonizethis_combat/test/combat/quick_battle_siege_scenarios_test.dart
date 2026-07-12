/// Combat-style scenarios for siege Quick Battle: virtual emplaced guns absorb
/// defender-side damage before/during regiment losses; fort may downgrade when
/// all guns are destroyed. SPEC/game/quick-battle.md, SPEC/program/quick-battle-resolution.md.
library;
import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'Quick Battle siege scenarios (emplaced targeting)',
    quickBattleSiegeScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'Quick Battle initiative scenarios',
    quickBattleInitiativeScenarios(),
    (s) => s.run(),
  );
}
