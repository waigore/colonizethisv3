// Shared fixtures for COLONIAL personality divergence pins (Refs #2509 must-have #4).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kPersonalityColonialDivergenceNationId = kOrchestratorGp1NationId;
const String kPersonalityColonialDivergenceTribeId = kOrchestratorTribeId;

const List<DiplomaticOrder> kPersonalityColonialDivergenceCandidates =
    <DiplomaticOrder>[
  DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: kPersonalityColonialDivergenceTribeId,
  ),
  DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: kPersonalityColonialDivergenceTribeId,
    overtureStage: OvertureStage.joinEmpire,
  ),
];

const int kPersonalityColonialDivergenceDeclareWarIdx = 0;
const int kPersonalityColonialDivergenceEstablishOvertureIdx = 1;

const AIConfig kPersonalityColonialDivergenceNapoleonConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'merchant',
);
const AIConfig kPersonalityColonialDivergenceHenryConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

List<int> personalityColonialDivergenceScoresFor(AIConfig config) {
  final game = diplomaticCandidateScoringColonialTribeScenarioGame(
    gameId: 'g-2509-personality-must-have-4-colonial',
    overtureStates: kDiplomaticCandidateScoringPersonalityOvertures,
  );
  final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
    newWorldProvincesOwned: 1,
    tribeRelationScore: 30,
    adjacentNewWorldOwnerFactionIdsSorted: const <String>[],
  );
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: kPersonalityColonialDivergenceCandidates,
      nationId: kPersonalityColonialDivergenceNationId,
      game: game,
      snapshot: snapshot,
      config: config,
    ),
  );
}

int personalityColonialDivergenceIndexOfMax(List<int> scores) {
  var bestIndex = 0;
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[bestIndex]) {
      bestIndex = i;
    }
  }
  return bestIndex;
}
