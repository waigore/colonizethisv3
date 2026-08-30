// Shared fixtures for Phase 3 diplomacy declare-war NW suppression pins (Refs #2847).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/phase_planner_diplomacy_filter_test_support.dart';

const PhasePriorityWeights kDiplomacyNwSuppressionZeroAcquisition =
    PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const AIConfig kDiplomacyNwSuppressionConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

const AIWorldSnapshot kDiplomacyNwSuppressionAtQuotaColonialAdjacentTribeSnap =
    AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
    provincesToVictory: 14,
    adjacentOwnerFactionIdsSorted: [],
  ),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_a'],
    adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
  ),
  economy: EconomySummary(),
  relations: {},
);

int diplomacyNwSuppressionTribeDeclareWarScore({
  required PhasePlanOutcome? phasePlan,
}) {
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: const [
        DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'tribe1',
        ),
      ],
      nationId: 'gp1',
      game: buildPhasePlannerDiplomacyNwSuppressionGame(),
      snapshot: kDiplomacyNwSuppressionAtQuotaColonialAdjacentTribeSnap,
      config: kDiplomacyNwSuppressionConfig,
      phasePlan: phasePlan,
    ),
  ).single;
}
