// Shared Game / snapshot fixtures for phase priority weights pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';

const String kPhasePriorityWeightsGp1 = 'gp1';
const String kPhasePriorityWeightsGp2 = 'gp2';
const String kPhasePriorityWeightsOwProvGp1 = 'oldWorld|gp1_a';
const String kPhasePriorityWeightsOwProvMinor = 'oldWorld|m1_a';

const ExpandEconomyPlan kPhasePriorityWeightsDefaultExpandPlan =
    ExpandEconomyPlan.defaultPlan;
const ExpandEconomyPlan kPhasePriorityWeightsBoostCargoPlan = ExpandEconomyPlan(
  forceCheapestRegimentBuild: false,
  boostTreasuryRecoveryCargo: true,
);

Game phasePriorityWeightsGameWithRegiments(int regimentCount) {
  return phasePriorityWeightsGameWithRegimentsAndTreasury(
    regimentCount: regimentCount,
    treasury: 0,
  );
}

Game phasePriorityWeightsGameWithRegimentsAndTreasury({
  required int regimentCount,
  required int treasury,
}) {
  return Game(
    id: 'g-2847-phase-priority-weights-r${regimentCount}_t$treasury',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 30, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: kPhasePriorityWeightsOwProvGp1,
            regionId: kOldWorldRegionId,
            ownerId: kPhasePriorityWeightsGp1,
          ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: regimentCount > 0
          ? [homeArmyWithRegiments(kPhasePriorityWeightsGp1, regimentCount)]
          : const [],
    ),
    players: [
      Player(
        id: kPhasePriorityWeightsGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: treasury,
      ),
      const Player(
        id: kPhasePriorityWeightsGp2,
        displayName: 'GP2',
        isHuman: false,
      ),
    ],
  );
}

AIWorldSnapshot phasePriorityWeightsSnapshot({
  required int oldWorldProvincesOwned,
  int treasury = 1000,
  int newWorldProvincesOwned = 1,
  List<String> invadable = const [kPhasePriorityWeightsOwProvMinor],
}) {
  return AIWorldSnapshot(
    playerId: kPhasePriorityWeightsGp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadable,
    ),
    colonial: ColonialSummary(newWorldProvincesOwned: newWorldProvincesOwned),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}
