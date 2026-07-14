// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'diplomatic_candidate_scoring_suppression_colonial_quota_cases.dart';
import 'diplomatic_candidate_scoring_suppression_colonial_adjacent_cases.dart';

void registerDiplomaticCandidateScoringSuppressionColonialCases() {
  registerDiplomaticCandidateScoringSuppressionColonialQuotaCases();
  registerDiplomaticCandidateScoringSuppressionColonialAdjacentCases();
}
