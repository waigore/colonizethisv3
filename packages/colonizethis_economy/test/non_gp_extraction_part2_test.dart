// Part 2: negative / boundary / multi-faction tests for
// `computeNonGreatPowerExtraction` — Issue #2991 C2.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (boundary + multi-faction)', () {
    for (final scenario in nonGpExtractionBoundaryScenarios()) {
      test(scenario.label, () => runNonGpExtractionScenario(scenario));
    }
  });
}
