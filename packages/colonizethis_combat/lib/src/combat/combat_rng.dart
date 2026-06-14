// SPDX-License-Identifier: Apache-2.0

import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'conflict_detection.dart';
import 'deterministic_rng.dart';

/// Single seam for constructing every random-number generator used by combat
/// resolution (Refs #3448).
///
/// All combat RNG must be built here so the seed recipes have one source of
/// truth and stay aligned with the determinism contract in
/// `SPEC/program/combat-resolution.md` (§3 binding recipe, "No global RNG
/// access; callers provide explicit seed when randomness is needed"). Each
/// factory below documents whether it derives its seed from the game replay
/// state (`globalGameSeed` + turn + context identity) or from a caller-supplied
/// per-engagement seed.
///
/// These factories are intentionally thin wrappers around `Random` /
/// [DeterministicRng]: they preserve the exact construction expressions that
/// previously lived inline in the resolvers, so observable outcomes are
/// identical for any fixed input.

/// Seed token mixed into the pre-Combat general-binding hash. Matches the recipe
/// in `SPEC/program/combat-resolution.md` §3 ("Binding RNG").
const String kPreCombatBindingSeedToken = 'preCombatGenerals';

/// RNG for the once-per-phase pre-Combat general binding pass.
///
/// Replay-stable: seeded from `hash(globalGameSeed, turnNumber,
/// "preCombatGenerals")` per `SPEC/program/combat-resolution.md` §3 so
/// auto-resolve and Quick Battle input build produce identical bindings.
Random preCombatBindingRng(Game game) {
  return Random(
    Object.hash(
      game.globalGameSeed ?? 0,
      game.worldState.turnState.turnNumber,
      kPreCombatBindingSeedToken,
    ),
  );
}

/// RNG for per-`BattleContext` general assignment and initiative tie-breaks.
///
/// Replay-stable: seeded from `hash(globalGameSeed, turnNumber, regionId,
/// provinceId)` so each province battle is deterministic and independent.
Random battleAssignmentRng(Game game, BattleContext ctx) {
  return Random(
    Object.hash(
      game.globalGameSeed ?? 0,
      game.worldState.turnState.turnNumber,
      ctx.regionId,
      ctx.provinceId,
    ),
  );
}

/// RNG for the Quick Battle resolver pipeline.
///
/// Caller-seeded: the per-engagement `seed` is supplied on `QuickBattleInput`;
/// the same seed yields an identical Quick Battle outcome.
Random quickBattleRng(int seed) => Random(seed);

/// RNG for the probabilistic per-engagement resolver.
///
/// Caller-seeded with a nullable seed; a `null` seed falls back to `0` so
/// repeated calls without an explicit seed remain deterministic.
Random probabilisticEngagementRng(int? seed) => Random(seed ?? 0);

/// RNG for naval combat (interception filtering and sea-battle resolution).
///
/// Replay-stable: callers pass a seed derived from game + sea-zone identity;
/// uses the 31-bit LCG [DeterministicRng] for replay-stable rolls.
DeterministicRng navalCombatRng(int seed) => DeterministicRng(seed);
