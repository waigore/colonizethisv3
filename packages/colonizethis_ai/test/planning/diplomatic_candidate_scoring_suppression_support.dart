// Shared scaffolding for the consolidation of diplomatic candidate scoring
// suppression suites (Refs #3941).
//
// Case tables live in sibling `*_cases.dart` modules so the single contract
// file `diplomatic_candidate_scoring_suppression_test.dart` stays under the
// non-comment line gate.

import 'package:colonizethis_test/test.dart';

/// Registers a topical case group under [groupLabel].
void registerDiplomaticScoringSuppressionGroup(
  String groupLabel,
  void Function() registerCases,
) {
  group(groupLabel, registerCases);
}
