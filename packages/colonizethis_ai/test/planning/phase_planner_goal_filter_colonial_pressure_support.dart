// Fixtures for Phase 3 colonial-pressure soft-weight pins (Refs #2847 / #4602).
// Contract: SPEC/ai/ phase-planner dispatch + goal-score colonial pressure.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

const AIConfig kColonialPressureSoftWeightConfig = AIConfig(
  leaderId: 'victoria',
  personalityId: 'victoria',
  hiddenAgendaId: 'peacemaker',
);

const AIWorldSnapshot kColonialPressureSoftWeightSnapshot = AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
    provincesToVictory: 14,
  ),
  colonial: ColonialSummary(
    newWorldProvincesOwned: kColonialFewNwProvincesThreshold,
    invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
    adjacentNewWorldOwnerFactionIdsSorted: ['tribe1'],
  ),
  economy: EconomySummary(treasury: 10000),
  relations: {},
);

Map<StrategicGoal, int> colonialPressureScoresWithWeight(double? weight) {
  return evaluateStrategicGoalScores(
    kColonialPressureSoftWeightSnapshot,
    kColonialPressureSoftWeightConfig,
    colonialPressureWeight: weight,
  );
}
