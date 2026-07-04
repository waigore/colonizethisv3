import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('detectConflicts', () {
    for (final scenario in detectConflictsScenarios()) {
      test(scenario.label, () => runConflictDetectionScenario(scenario));
    }
  });
}
