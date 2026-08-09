// Turn-seed helper for simple AI heuristics (Refs #4084 Slice B).
// Extracted from `simple_ai_heuristics.dart` so the seed concern stays a
// proper library with explicit imports (no `part` / `part of`).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Derives turn seed per ai-planner: turnSeed = hash(globalGameSeed, aiSeed[P], T).
/// When [fallbackAiSeed] is provided and [game.aiSeedByGpId] has no entry for
/// [playerId], it is used so that Option A (same seed when same role) holds.
int turnSeedForPlayer(
  Game game,
  String playerId,
  int turnNumber, {
  int? fallbackAiSeed,
}) {
  final global = game.globalGameSeed ?? 0;
  final aiSeed =
      game.aiSeedByGpId[playerId] ?? fallbackAiSeed ?? playerId.hashCode;
  var h = global ^ (turnNumber * kDeterministicHashMixPrime32);
  h ^= aiSeed * kDeterministicHashMixPrime32;
  return h & kDeterministicLcg31Mask;
}
