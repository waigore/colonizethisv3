/// Phase-planner dispatch Game / snapshot scaffolds for COLONIAL support
/// pins (Refs #3977 / #3997).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';
import 'colonial_phase_planner_test_support_core.dart';

/// Phase-planner dispatch COLONIAL-lite Game: turn ≥ 120, OW near quota
/// scaffold with a tribe-owned NW province (Refs #3977).
Game buildPhasePlannerDispatchColonialLiteGame({
  int turnNumber = kObserverColonialLiteMinTurn + 5,
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: turnNumber,
    gameId: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
      Province(
        id: kColonialPhaseDispatchOwProvMinor,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseMinor1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kColonialPhaseMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch COLONIAL Game: OW at quota with NW invadable
/// tribe province and Home Army regiment count (Refs #3977).
Game buildPhasePlannerDispatchColonialGame({
  int regimentCount = 6,
  int ownTreasury = 9999,
}) {
  return buildColonialPhaseGame(
    turnNumber: 130,
    gameId: 'g-2509-phase-planner-dispatch-colonial',
    oldWorldProvinces: const [
      Province(
        id: kColonialPhaseDispatchOwProvGp1,
        regionId: kOldWorldRegionId,
        ownerId: kColonialPhaseGp1,
      ),
    ],
    newWorldProvinces: const [
      Province(
        id: kColonialPhaseNwProvTribeA,
        regionId: kNewWorldRegionId,
        ownerId: kColonialPhaseTribe1,
      ),
    ],
    armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch EXPAND Game: below-quota OW minor frontier,
/// empty NW so routing cannot flip to COLONIAL-lite / COLONIAL
/// (Refs #3997).
Game buildPhasePlannerDispatchExpandGame({
  int turnNumber = 50,
  int regimentCount = 6,
  int ownTreasury = 9999,
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: kColonialPhaseDispatchOwProvGp1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: kColonialPhaseDispatchOwProvMinor,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseMinor1,
          ),
        ],
      ),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: [homeArmyWithRegiments(kColonialPhaseGp1, regimentCount)],
    ),
    players: [
      Player(
        id: kColonialPhaseGp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: kColonialPhaseMinor1, displayName: 'Minor1'),
    ],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'Tribe1')],
  );
}

/// Phase-planner dispatch DEVELOP Game: OW at quota with all NW
/// GP-owned so COLONIAL-lite preconditions fail (Refs #3997).
Game buildPhasePlannerDispatchDevelopGame() {
  return Game(
    id: 'g-2509-phase-planner-dispatch-develop',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: kColonialPhaseDispatchOwProvGp1,
            regionId: kOldWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|gp2_owned',
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp2,
          ),
        ],
      ),
    ),
    players: const [
      Player(id: kColonialPhaseGp1, displayName: 'GP1', isHuman: false),
      Player(id: kColonialPhaseGp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

/// Snapshot for dispatch EXPAND posture: OW below quota, OW invadable
/// populated (Refs #3997).
AIWorldSnapshot buildPhasePlannerDispatchExpandSnapshot({
  int oldWorldProvincesOwned = 8,
  List<String> atWarWith = const <String>[],
  List<String> adjacentOwners = const <String>[kColonialPhaseMinor1],
}) {
  return AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: const [kColonialPhaseDispatchOwProvMinor],
      adjacentOwnerFactionIdsSorted: adjacentOwners,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Snapshot for dispatch COLONIAL-lite posture: OW = 9, NW tribe
/// summary populated (Refs #3997).
AIWorldSnapshot buildPhasePlannerDispatchColonialLiteSnapshot() {
  return const AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: [kColonialPhaseDispatchOwProvMinor],
      adjacentOwnerFactionIdsSorted: [kColonialPhaseMinor1],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [kColonialPhaseNwProvTribeA],
      adjacentNewWorldOwnerFactionIdsSorted: [kColonialPhaseTribe1],
      preferredColonialTargetFactionIdsSorted: [kColonialPhaseTribe1],
    ),
    economy: EconomySummary(),
    relations: {},
  );
}

/// Snapshot for dispatch COLONIAL posture: OW at quota, NW invadable,
/// economy treasury for acquisition declareWar gate (Refs #3997).
AIWorldSnapshot buildPhasePlannerDispatchColonialSnapshot({
  List<String> atWarWith = const <String>[kColonialPhaseTribe1],
  int treasury = 9999,
}) {
  return AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [kColonialPhaseNwProvTribeA],
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

/// Snapshot for dispatch DEVELOP posture: OW at quota, empty colonial
/// summary, one at-war GP for non-empty peace (Refs #3997).
AIWorldSnapshot buildPhasePlannerDispatchDevelopSnapshot() {
  return const AIWorldSnapshot(
    playerId: kColonialPhaseGp1,
    threats: ThreatSummary(atWarWith: [kColonialPhaseGp3]),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(),
    relations: {},
  );
}
