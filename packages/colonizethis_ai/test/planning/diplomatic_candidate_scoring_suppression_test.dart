// Table-driven consolidation of diplomatic candidate scoring suppression
// suites (Refs #3941).
//
// Single contract file: core, EXPAND, and COLONIAL suppression pins. Case
// bodies live in topical `*_cases.dart` modules; shared registration helpers
// in `diplomatic_candidate_scoring_suppression_support.dart`.
//
// Coverage is preserved 1:1 from the former part2/part3 shards.

import 'diplomatic_candidate_scoring_suppression_colonial_cases.dart';
import 'diplomatic_candidate_scoring_suppression_core_cases.dart';
import 'diplomatic_candidate_scoring_suppression_expand_cases.dart';

void main() {
  registerDiplomaticCandidateScoringSuppressionCoreCases();
  registerDiplomaticCandidateScoringSuppressionExpandCases();
  registerDiplomaticCandidateScoringSuppressionColonialCases();
}
