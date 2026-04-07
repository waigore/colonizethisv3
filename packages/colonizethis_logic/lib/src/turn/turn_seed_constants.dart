/// Deterministic mixing and LCG parameters for turn-resolution sub-seeds.
/// Used with [Game.globalGameSeed] and turn number so previews and full
/// resolution stay aligned (e.g. overseas interception, combat dialogue).

/// Golden-ratio–derived 32-bit mix constant; common in hash / PRNG mixing.
const int kTurnResolutionSeedMix = 0x9E3779B1;

/// glibc-style linear congruential step (mod 2^31).
const int kTurnResolutionLcgMultiplier = 1103515245;
const int kTurnResolutionLcgIncrement = 12345;
const int kTurnResolutionLcgMask = 0x7fffffff;
