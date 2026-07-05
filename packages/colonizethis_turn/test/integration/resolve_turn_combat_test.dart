// Integration domain entrypoint (Refs #3876).
import 'package:colonizethis_test/test.dart';
import '../support/integration/resolve_turn_combat_movement_scenarios.dart';
import '../support/integration/resolve_turn_combat_movement_orders_scenarios.dart';
import '../support/integration/resolve_turn_combat_movement_dialogue_scenarios.dart';
import '../support/integration/resolve_turn_combat_resolution_scenarios.dart';
import '../support/integration/resolve_turn_combat_resolution_continued_scenarios.dart';

void main() {
  group('integration domain', () {
  registerCombatMovementTests();
  registerCombatMovementOrdersTests();
  registerCombatMovementDialogueTests();
  registerCombatResolutionTests();
  registerCombatResolutionContinuedTests();
  });
}
