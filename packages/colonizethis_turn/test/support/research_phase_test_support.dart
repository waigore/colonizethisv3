import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared fixtures for research-phase tests (Refs #2216).
Game researchPhaseTestBaseGame({
  required int treasury,
  Map<String, bool>? techUnlocked,
  Map<String, int>? progress,
  int? researchSlots,
}) {
  return TestFixtures.singlePlayerGame(
    Player(
      id: 'p1',
      displayName: 'Player 1',
      isHuman: true,
      treasury: treasury,
      techUnlocked: techUnlocked,
      researchProgressByTechId: progress,
      researchSlots: researchSlots,
    ),
    worldState: TestFixtures.worldStateAtOrdersPhase(turnNumber: 0),
  );
}

/// Human + AI on turn 2 (envy evidence when mirroring research category).
Game researchPhaseTestHumanAiMirrorResearchGame() {
  return TestFixtures.twoPlayerGame(
    player1: const Player(
      id: 'h1',
      displayName: 'Human',
      isHuman: true,
      treasury: 10000,
      researchSlots: 1,
      techUnlocked: {},
    ),
    player2: const Player(
      id: 'a1',
      displayName: 'AI',
      isHuman: false,
      treasury: 10000,
      researchSlots: 1,
      techUnlocked: {},
    ),
    worldState: TestFixtures.worldStateAtOrdersPhase(turnNumber: 2),
  ).copyWith(aiControlByGpId: const {'a1': true});
}

/// Two human players, orders phase turn 0 (partial research orders).
Game researchPhaseTestTwoHumanPlayersOrdersTurn0() {
  return TestFixtures.twoPlayerGame(
    player1: const Player(
      id: 'p1',
      displayName: 'P1',
      isHuman: true,
      treasury: 2000,
      researchSlots: 1,
    ),
    player2: const Player(
      id: 'p2',
      displayName: 'P2',
      isHuman: true,
      treasury: 500,
      researchSlots: 1,
    ),
    worldState: TestFixtures.worldStateAtOrdersPhase(turnNumber: 0),
  );
}
