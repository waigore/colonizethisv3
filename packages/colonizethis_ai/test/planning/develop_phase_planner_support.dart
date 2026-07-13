// Shared fixtures for develop-phase planner pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kDevelopPhaseGp1 = 'gp1';
const String kDevelopPhaseGp2 = 'gp2';
const String kDevelopPhaseGp3 = 'gp3';
const String kDevelopPhaseGp4 = 'gp4';
const String kDevelopPhaseTribe1 = 'tribe1';
const String kDevelopPhaseMinor1 = 'minor1';

/// Game scaffold with a 4-GP roster. Tribes / minors are added only when a
/// test needs to exercise the non-GP filter via [Game.playerById].
Game developPhaseTestGame({
  List<Player> players = const [
    Player(id: kDevelopPhaseGp1, displayName: 'GP1', isHuman: false),
    Player(id: kDevelopPhaseGp2, displayName: 'GP2', isHuman: false),
    Player(id: kDevelopPhaseGp3, displayName: 'GP3', isHuman: false),
    Player(id: kDevelopPhaseGp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-develop-phase-planner-peace',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Minimal snapshot with the active player [kDevelopPhaseGp1] and a configurable
/// at-war roster. The phase-routing fields (`conquest`, `colonial`) are
/// left empty: the planner does not re-check phase, so these tests stay
/// scoped to the in-module peace contract.
AIWorldSnapshot developPhaseTestSnapshot({required List<String> atWarWith}) {
  return AIWorldSnapshot(
    playerId: kDevelopPhaseGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
