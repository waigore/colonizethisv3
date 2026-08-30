// Shared scoring fixtures for issue #2509 must-have #6 intervention tolerance pins
// (Refs #4669 Slice D densify).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomatic_candidate_scoring_colonial_test_support.dart';
import '../support/domain_planner_orchestrator_test_support.dart';

const String kInterventionTribeToleranceNationId = kOrchestratorGp1NationId;
const String kInterventionTribeToleranceTribeId = kOrchestratorTribeId;

// COLONIAL-phase tribe target. Only a single declare-war candidate is
// scored so the assertion can pin the tribe declare-war slot directly
// without depending on the relative ordering of unrelated candidates.
const List<DiplomaticOrder> kInterventionTribeDeclareWarCandidates =
    <DiplomaticOrder>[
  DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: kInterventionTribeToleranceTribeId,
  ),
];

// `merchant` is intentionally not in any of `agendaConquerModifiers`,
// `agendaTreatyBreakingModifiers`, `agendaAllianceAcceptanceModifiers`,
// or `declareWarMaxRelationScoreByAgenda`, so every agenda modifier
// resolves to its zero / default fallback. The intervention-risk delta
// the AC pins is then driven by the war-desire bonus path inside
// `_declareWarCoreBonuses` rather than by hidden-agenda shifts that
// would change between fixtures.
//
// `victoria` (personalityId) keeps `warLikelihood` = 50 /
// `allianceTendency` = 50, so the personality term in
// `_declareWarCoreBonuses` is exactly zero — the residual cross-fixture
// score delta isolates the intervention-risk path the AC pins.
const AIConfig kInterventionTribeToleranceAiConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'merchant',
);

/// COLONIAL-phase snapshot mirroring the AC's "tribe is a valid
/// declare-war target, colonial-support weights are active"
/// preconditions.
List<int> scoreInterventionTribeDeclareWar({
  required List<OvertureState> overtureStates,
}) {
  final game = diplomaticCandidateScoringColonialTribeScenarioGame(
    gameId: 'g-2509-intervention-tribe-tolerance',
    overtureStates: overtureStates,
    includeBystanderGreatPowers: true,
    homeArmyRegimentUnitId: 'u_gp1_home',
  );
  final snapshot = buildOrchestratorColonialNwTribeTargetSnapshot(
    newWorldProvincesOwned: 1,
    tribeRelationScore: 30,
    adjacentNewWorldOwnerFactionIdsSorted: const <String>[],
  );
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: kInterventionTribeDeclareWarCandidates,
      nationId: kInterventionTribeToleranceNationId,
      game: game,
      snapshot: snapshot,
      config: kInterventionTribeToleranceAiConfig,
    ),
  );
}
