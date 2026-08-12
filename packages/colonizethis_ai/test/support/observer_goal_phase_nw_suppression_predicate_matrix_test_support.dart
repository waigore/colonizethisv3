// Shared Game / snapshot fixtures for observer-phase NW-suppression predicate
// matrix pins (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kObserverGoalPhaseNwSuppressionMatrixNationId = 'gp1';
const String kObserverGoalPhaseNwSuppressionMatrixTribeId = 'tribe1';
const String kObserverGoalPhaseNwSuppressionMatrixNwTribeProvince =
    'newWorld|tribe1_nw0';
const String kObserverGoalPhaseNwSuppressionMatrixNwGpOwnedProvince =
    'newWorld|gp1_nw0';

/// Game fixture used for the EXPAND, COLONIAL-lite, and COLONIAL branches.
Game observerGoalPhaseNwSuppressionMatrixGameWithTribeNw({
  required int turnNumber,
}) {
  return Game(
    id: 'g-2509-nw-suppression-predicate-matrix',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: kObserverGoalPhaseNwSuppressionMatrixNwTribeProvince,
            regionId: kNewWorldRegionId,
            ownerId: kObserverGoalPhaseNwSuppressionMatrixTribeId,
          ),
        ],
      ),
    ),
    players: const [
      Player(
        id: kObserverGoalPhaseNwSuppressionMatrixNationId,
        displayName: 'P1',
        isHuman: false,
      ),
    ],
    tribes: const [
      Tribe(
        id: kObserverGoalPhaseNwSuppressionMatrixTribeId,
        displayName: 'T1',
      ),
    ],
    minorNations: const [],
  );
}

/// Game fixture used for the DEVELOP branch — every visible NW province is
/// GP-owned so `hasColonialAcquisitionTargets` is false.
Game observerGoalPhaseNwSuppressionMatrixGameWithGpOwnedNw() {
  return Game(
    id: 'g-2509-nw-suppression-predicate-matrix-develop',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 140,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: kObserverGoalPhaseNwSuppressionMatrixNwGpOwnedProvince,
            regionId: kNewWorldRegionId,
            ownerId: kObserverGoalPhaseNwSuppressionMatrixNationId,
          ),
        ],
      ),
    ),
    players: const [
      Player(
        id: kObserverGoalPhaseNwSuppressionMatrixNationId,
        displayName: 'P1',
        isHuman: false,
      ),
    ],
    tribes: const [],
    minorNations: const [],
  );
}

/// Snapshot for EXPAND: below the observer OW quota.
const AIWorldSnapshot kObserverGoalPhaseNwSuppressionMatrixExpandSnapshot =
    AIWorldSnapshot(
  playerId: kObserverGoalPhaseNwSuppressionMatrixNationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 7),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixNwTribeProvince,
    ],
    adjacentNewWorldOwnerFactionIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixTribeId,
    ],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for COLONIAL-lite at the near-quota OW floor.
const AIWorldSnapshot kObserverGoalPhaseNwSuppressionMatrixColonialLiteSnapshot =
    AIWorldSnapshot(
  playerId: kObserverGoalPhaseNwSuppressionMatrixNationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
  ),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixNwTribeProvince,
    ],
    adjacentNewWorldOwnerFactionIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixTribeId,
    ],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for COLONIAL at quota with visible acquisition targets.
const AIWorldSnapshot kObserverGoalPhaseNwSuppressionMatrixColonialSnapshot =
    AIWorldSnapshot(
  playerId: kObserverGoalPhaseNwSuppressionMatrixNationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixNwTribeProvince,
    ],
    adjacentNewWorldOwnerFactionIdsSorted: [
      kObserverGoalPhaseNwSuppressionMatrixTribeId,
    ],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for DEVELOP at quota with no colonial acquisition targets.
const AIWorldSnapshot kObserverGoalPhaseNwSuppressionMatrixDevelopSnapshot =
    AIWorldSnapshot(
  playerId: kObserverGoalPhaseNwSuppressionMatrixNationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(newWorldProvincesOwned: 1),
  economy: EconomySummary(),
  relations: {},
);
