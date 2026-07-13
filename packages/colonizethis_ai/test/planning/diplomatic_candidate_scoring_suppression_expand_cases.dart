// Case-library barrel (Refs #3997 Phase 8).
// Thin aggregator so existing contracts keep a stable import;
// topic modules stay ≤650 physical lines.

import 'diplomatic_candidate_scoring_suppression_expand_blocker_cases.dart';
import 'diplomatic_candidate_scoring_suppression_expand_below_quota_cases.dart';

void registerDiplomaticCandidateScoringSuppressionExpandCases() {
  registerDiplomaticCandidateScoringSuppressionExpandBlockerCases();
  registerDiplomaticCandidateScoringSuppressionExpandBelowQuotaCases();
}
