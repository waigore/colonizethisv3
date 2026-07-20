// Shared Game factories for phase-diplomacy soft-weight filter pins
// (Refs #4104 Slice A).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

Game buildPhasePlannerDiplomacyOwBonusScalingGame() => Game(
  id: 'g-phase3-diplomacy-ow-soft-weight',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: 'oldWorld|minor1_a',
          regionId: 'oldWorld',
          ownerId: 'minor1',
        ),
      ],
    ),
    newWorld: const RegionData(),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  aiControlByGpId: const {'gp1': true},
);

Game buildPhasePlannerDiplomacyNwSuppressionGame() => Game(
  id: 'g-phase3-diplomacy-soft-weight',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
    oldWorld: const RegionData(),
    newWorld: const RegionData(
      provinces: [
        Province(
          id: 'newWorld|tribe1_a',
          regionId: 'newWorld',
          ownerId: 'tribe1',
        ),
      ],
    ),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
  tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
  aiControlByGpId: const {'gp1': true},
);
