// Thin contract for diplomatic_candidate_scoring pin suite (Refs #3997 Phase 8).
// Case bodies live in sibling `*_cases.dart` modules.

import 'diplomatic_candidate_scoring_core_early_cases.dart';
import 'diplomatic_candidate_scoring_core_later_cases.dart';

void main() {
  registerDiplomaticCandidateScoringCoreEarlyCases();
  registerDiplomaticCandidateScoringCoreLaterCases();
}
