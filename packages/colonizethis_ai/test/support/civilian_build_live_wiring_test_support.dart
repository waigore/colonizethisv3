// Shared Game fixtures for civilian_build_live_wiring pins
// (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game civilianBuildLiveWiringGameWithLeader() => Game(
  id: 'g-civ-wire',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(
      id: 'gp1',
      displayName: 'Leader',
      isHuman: false,
      treasury: 1000,
      leaderKey: 'victoria',
    ),
  ],
);
