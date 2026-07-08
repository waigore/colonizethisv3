// Table-driven tests for `computeNonGreatPowerExtraction` — Issue #2991 C2.
//
// SPEC: `SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (SPEC ACs)', () {
    for (final scenario in nonGpExtractionSpecAcScenarios()) {
      test(scenario.label, () => runNonGpExtractionScenario(scenario));
    }
  });

  group('computeNonGreatPowerExtraction (boundary + multi-faction)', () {
    for (final scenario in nonGpExtractionBoundaryScenarios()) {
      test(scenario.label, () => runNonGpExtractionScenario(scenario));
    }
  });
}
