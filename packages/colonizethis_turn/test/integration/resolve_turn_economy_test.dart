// Integration domain entrypoint (Refs #3876).
import 'package:colonizethis_test/test.dart';
import '../support/integration/resolve_turn_economy_scenarios.dart';
import '../support/integration/resolve_turn_economy_continued_scenarios.dart';

void main() {
  group('integration domain', () {
  registerEconomyCoreTests();
  registerEconomyContinuedTests();
  });
}
