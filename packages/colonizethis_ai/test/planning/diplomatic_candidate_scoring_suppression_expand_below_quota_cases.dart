// Case-library barrel (Refs #3997 Phase 8 / #4104 Slice C).
// Thin aggregator; topic modules stay under 600 physical lines.

import 'diplomatic_candidate_scoring_suppression_expand_below_quota_early_cases.dart';
import 'diplomatic_candidate_scoring_suppression_expand_below_quota_late_cases.dart';

void registerDiplomaticCandidateScoringSuppressionExpandBelowQuotaCases() {
  registerDiplomaticCandidateScoringSuppressionExpandBelowQuotaEarlyCases();
  registerDiplomaticCandidateScoringSuppressionExpandBelowQuotaLateCases();
}
