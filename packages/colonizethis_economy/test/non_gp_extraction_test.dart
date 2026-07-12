// Table-driven tests for `computeNonGreatPowerExtraction` — Issue #2991 C2.
//
// SPEC: `SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (SPEC ACs)', () {
    runLabeledScenarios(nonGpExtractionSpecAcScenarios(), (scenario) {
      runNonGpExtractionScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('computeNonGreatPowerExtraction (boundary + multi-faction)', () {
    runLabeledScenarios(nonGpExtractionBoundaryScenarios(), (scenario) {
      runNonGpExtractionScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
