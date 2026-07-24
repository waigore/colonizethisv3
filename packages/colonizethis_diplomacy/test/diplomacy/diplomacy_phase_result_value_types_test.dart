import 'package:colonizethis_test/test.dart';

import 'diplomacy_phase_result_value_types_scenarios.dart';

/// Value-equality and pending-state coverage for the Diplomacy-phase value
/// types in `diplomacy_phase_result.dart` (Refs #3290 test migration —
/// per-package coverage gate for `colonizethis_diplomacy`).
void main() {
  for (final scenario in phaseResultValueTypeScenarios()) {
    test(scenario.label, scenario.run);
  }
}
