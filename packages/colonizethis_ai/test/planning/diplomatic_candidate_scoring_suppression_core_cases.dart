// Case-library barrel (Refs #3997 Phase 8 / #4291 Slice D).
// Thin aggregator so existing contracts keep a stable import.

import 'diplomatic_candidate_scoring_suppression_core_early_cases.dart';
import 'diplomatic_candidate_scoring_suppression_core_later_early_cases.dart';
import 'diplomatic_candidate_scoring_suppression_core_later_tail_cases.dart';

void registerDiplomaticCandidateScoringSuppressionCoreCases() {
  registerDiplomaticCandidateScoringSuppressionCoreEarlyCases();
  registerDiplomaticCandidateScoringSuppressionCoreLaterEarlyCases();
  registerDiplomaticCandidateScoringSuppressionCoreLaterTailCases();
}
