// Integration domain entrypoint (Refs #3876).
import 'package:colonizethis_test/test.dart';
import '../support/integration/resolve_turn_diplomacy_victory_scenarios.dart';
import '../support/integration/resolve_turn_diplomacy_victory_overtures_scenarios.dart';
import '../support/integration/resolve_turn_diplomacy_victory_endgame_scenarios.dart';

void main() {
  group('integration domain', () {
  registerDiplomacyVictoryCoreTests();
  registerDiplomacyVictoryOverturesTests();
  registerDiplomacyVictoryEndgameTests();
  });
}
