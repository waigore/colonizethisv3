// Shared Game fixtures for build_planner_civilian_scoring pins
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game buildPlannerCivilianScoringGame() => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(
      id: 'gp1',
      displayName: 'France',
      isHuman: false,
      leaderKey: 'napoleon',
    ),
  ],
);
