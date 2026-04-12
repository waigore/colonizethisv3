/// Deterministic mixing and LCG parameters for turn-resolution sub-seeds.
/// Used with [Game.globalGameSeed] and turn number so previews and full
/// resolution stay aligned (e.g. overseas interception, combat dialogue).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Golden-ratio–derived 32-bit mix constant; common in hash / PRNG mixing.
const int kTurnResolutionSeedMix = kDeterministicHashMixPrime32;

/// glibc-style linear congruential step (mod 2^31).
const int kTurnResolutionLcgMultiplier = kDeterministicLcgMultiplierGlibc;
const int kTurnResolutionLcgIncrement = kDeterministicLcgIncrementGlibc;
const int kTurnResolutionLcgMask = kDeterministicLcg31Mask;
