// Part 1: SPEC-AC tests for `computeNonGreatPowerExtraction` — Issue #2991 C2.
//
// Anchors the three SPEC contracts in
// `SPEC/game/extraction-and-improvements.md` § Non-Great-Power extraction.
// Negative/boundary and aggregation cases live in
// `non_gp_extraction_part2_test.dart`.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('computeNonGreatPowerExtraction (SPEC ACs)', () {
    for (final scenario in nonGpExtractionSpecAcScenarios()) {
      test(scenario.label, () => runNonGpExtractionScenario(scenario));
    }
  });
}
