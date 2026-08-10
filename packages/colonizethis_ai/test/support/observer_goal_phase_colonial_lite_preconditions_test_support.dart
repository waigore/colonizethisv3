// Shared Game / snapshot fixtures for COLONIAL-lite precondition pins
// (Refs #4310 Slice C).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kObserverGoalPhaseColonialLiteNationId = 'gp1';
const String kObserverGoalPhaseColonialLiteOtherGpId = 'gp2';
const String kObserverGoalPhaseColonialLiteTribeId = 'tribe1';
const String kObserverGoalPhaseColonialLiteMinorId = 'minor1';

/// Snapshot at the COLONIAL-lite near-quota lower boundary (OW = 9).
AIWorldSnapshot observerGoalPhaseColonialLiteSnapshotOw(int ow) {
  return AIWorldSnapshot(
    playerId: kObserverGoalPhaseColonialLiteNationId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: ow,
      // Non-empty so a tuning slice that filtered by invadable presence
      // does not silently force EXPAND for an unrelated reason.
      invadableProvinceIdsSorted: const ['oldWorld|minor_invadable'],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: ['newWorld|tribe1_nw0'],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Game with one NW province owned by [ownerId]. `null` means unowned.
Game observerGoalPhaseColonialLiteGameWithNwOwner({
  required int turnNumber,
  String? ownerId,
}) {
  return Game(
    id: 'g-2509-colonial-lite-pre-${ownerId ?? "unowned"}-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(
            id: 'newWorld|nw0',
            regionId: 'newWorld',
            ownerId: ownerId,
          ),
        ],
      ),
    ),
    players: const [
      Player(
        id: kObserverGoalPhaseColonialLiteNationId,
        displayName: 'GP1',
        isHuman: false,
      ),
      Player(
        id: kObserverGoalPhaseColonialLiteOtherGpId,
        displayName: 'GP2',
        isHuman: false,
      ),
    ],
    tribes: const [
      Tribe(id: kObserverGoalPhaseColonialLiteTribeId, displayName: 'T1'),
    ],
    minorNations: const [
      MinorNation(id: kObserverGoalPhaseColonialLiteMinorId, displayName: 'M1'),
    ],
  );
}

/// Game with NW provinces enumerated by owner — supports mixed-ownership cases.
Game observerGoalPhaseColonialLiteGameWithNwOwners({
  required int turnNumber,
  required List<String?> nwOwners,
}) {
  return Game(
    id: 'g-2509-colonial-lite-pre-multi-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          for (var i = 0; i < nwOwners.length; i++)
            Province(
              id: 'newWorld|nw$i',
              regionId: 'newWorld',
              ownerId: nwOwners[i],
            ),
        ],
      ),
    ),
    players: const [
      Player(
        id: kObserverGoalPhaseColonialLiteNationId,
        displayName: 'GP1',
        isHuman: false,
      ),
      Player(
        id: kObserverGoalPhaseColonialLiteOtherGpId,
        displayName: 'GP2',
        isHuman: false,
      ),
    ],
    tribes: const [
      Tribe(id: kObserverGoalPhaseColonialLiteTribeId, displayName: 'T1'),
    ],
    minorNations: const [
      MinorNation(id: kObserverGoalPhaseColonialLiteMinorId, displayName: 'M1'),
    ],
  );
}
