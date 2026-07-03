/// Deterministic mixing and LCG parameters for turn-resolution sub-seeds.
/// Used with [Game.globalGameSeed] and turn number so previews and full
/// resolution stay aligned (e.g. overseas interception, combat dialogue).
library;

import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

/// Golden-ratio–derived 32-bit mix constant; common in hash / PRNG mixing.
const int kTurnResolutionSeedMix = kDeterministicHashMixPrime32;

/// glibc-style linear congruential step (mod 2^31).
const int kTurnResolutionLcgMultiplier = kDeterministicLcgMultiplierGlibc;
const int kTurnResolutionLcgIncrement = kDeterministicLcgIncrementGlibc;
const int kTurnResolutionLcgMask = kDeterministicLcg31Mask;

/// Deterministic base sub-seed for [turn], mixing [Game.globalGameSeed] with the
/// turn number via [kTurnResolutionSeedMix]. Used as the seed root for combat
/// dialogue, land/naval battle resolution, and overseas interception so previews
/// and full resolution stay aligned for identical inputs.
int mixTurnSeed(Game game, int turn) =>
    (game.globalGameSeed ?? 0) ^ (turn * kTurnResolutionSeedMix);

/// Advances [seed] by one glibc-style linear congruential step (mod 2^31).
///
/// Canonical home for the LCG-advance arithmetic shared by extraction,
/// combat, and naval resolution so the inline literal lives in exactly one
/// file. Must stay bit-identical to the previous inline expression to keep
/// turn-resolution determinism (see SPEC/program/turn-resolution.md).
int advanceTurnSeed(int seed) =>
    (seed * kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement) &
    kTurnResolutionLcgMask;

/// Turn-linear mix constant unique to the spy-resolution sub-phase.
///
/// Spy uses additive mixing (not XOR [mixTurnSeed]) so existing spy outcomes
/// stay bit-identical for fixed `(globalGameSeed, turn)` pairs.
const int kSpyPhaseSeedTurnMultiplier = 7919;

/// Sub-seed for spy-resolution RNG on [turn].
///
/// Returns `null` when [Game.globalGameSeed] is unset (caller uses unseeded RNG).
int? mixSpyPhaseSeed(Game game, int turn) {
  final root = game.globalGameSeed;
  if (root == null) return null;
  return root + turn * kSpyPhaseSeedTurnMultiplier;
}

/// Deterministic [Random] for spy-resolution when [Game.globalGameSeed] is set.
Random spyPhaseRandom(Game game, {Random? override}) {
  if (override != null) return override;
  final seed = mixSpyPhaseSeed(game, game.worldState.turnState.turnNumber);
  if (seed == null) return Random();
  return Random(seed);
}
