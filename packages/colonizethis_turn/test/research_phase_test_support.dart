import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared fixtures for [research_phase_test.dart].
///
/// Refs waigore/colonizethis#2216.
Game researchPhaseTestBaseGame({
  required int treasury,
  Map<String, bool>? techUnlocked,
  Map<String, int>? progress,
  int? researchSlots,
}) {
  final player = Player(
    id: 'p1',
    displayName: 'Player 1',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
    researchProgressByTechId: progress,
    researchSlots: researchSlots,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [player]);
}

/// Human + AI on turn 2 (envy evidence when mirroring research category).
Game researchPhaseTestHumanAiMirrorResearchGame() {
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  );
  final human = Player(
    id: 'h1',
    displayName: 'Human',
    isHuman: true,
    treasury: 10000,
    researchSlots: 1,
    techUnlocked: const {},
  );
  final ai = Player(
    id: 'a1',
    displayName: 'AI',
    isHuman: false,
    treasury: 10000,
    researchSlots: 1,
    techUnlocked: const {},
  );
  return Game(
    id: 'g',
    worldState: world,
    players: [human, ai],
    aiControlByGpId: const {'a1': true},
  );
}

/// Two human players, orders phase turn 0 (partial research orders).
Game researchPhaseTestTwoHumanPlayersOrdersTurn0() {
  final p1 = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    treasury: 2000,
    researchSlots: 1,
  );
  final p2 = Player(
    id: 'p2',
    displayName: 'P2',
    isHuman: true,
    treasury: 500,
    researchSlots: 1,
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [p1, p2],
  );
}
