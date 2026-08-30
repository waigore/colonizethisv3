// Shared Game fixtures for phase_planner_economy_build_pick_cargo_bonus pin
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game phasePlannerEconomyBuildPickCargoBonusGame() => Game(
  id: 'g-phase3-economy-build-pick-soft-weight',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 40),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: false)],
);
