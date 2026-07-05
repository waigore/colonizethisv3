// Integration domain entrypoint (Refs #3876).
import 'package:colonizethis_test/test.dart';
import '../support/integration/resolve_turn_spy_fog_end_of_turn_scenarios.dart';
import '../support/integration/resolve_turn_spy_fog_end_of_turn_visibility_scenarios.dart';

void main() {
  group('integration domain', () {
  registerSpyFogEndOfTurnTests();
  registerSpyFogEndOfTurnVisibilityTests();
  });
}
