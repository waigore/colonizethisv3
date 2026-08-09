// Barrel for colonial-adjacent suppression case modules (Refs #4239 Slice C).

import 'diplomatic_candidate_scoring_suppression_colonial_adjacent_early_cases.dart';
import 'diplomatic_candidate_scoring_suppression_colonial_adjacent_late_cases.dart';

void registerDiplomaticCandidateScoringSuppressionColonialAdjacentCases() {
  registerDiplomaticScoringSuppressionColonialAdjacentEarlyCases();
  registerDiplomaticScoringSuppressionColonialAdjacentLateCases();
}
