// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

/// Shared effective-strength pipeline for all combat resolvers.
///
/// SPEC/program/combat-resolution.md, SPEC/program/quick-battle-resolution.md.
///
/// Auto-resolve ([resolveEngagement]), the probabilistic resolver
/// ([resolveEngagementProbabilistic]), and Quick Battle each computed the
/// `rawStrength → terrain × multipliers → fort reduction / emplaced add → wall
/// HP soak` pipeline independently. This module hosts the single shared
/// implementation so the three resolvers stay numerically in lockstep.
///
/// ## Determinism contract
///
/// Floating-point multiplication is commutative but **not** associative, so the
/// per-side multipliers are applied as an explicit left-associative chain in the
/// caller-provided order ([factor1] then [factor2] then [factor3], each
/// defaulting to the identity `1.0`). Multiplying by `1.0` is the IEEE-754
/// identity, so resolvers that use fewer factors omit the trailing ones without
/// changing a single bit. Callers MUST pass factors in the same order the
/// previous inline implementations used.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'combat_constants.dart';

bool _fortAppliesForCombatModifiers(int fortLevel) =>
    fortLevel >= kMinFortLevelForCombatModifiers &&
    fortLevel <= kMaxFortLevelForCombatModifiers;

/// Attacker effective strength: `base × factor1 × factor2 × factor3`, scaled by
/// the fort damage-reduction factor when [fortLevel] is in the siege range.
///
/// Factors are applied left-to-right in the listed order; see the module-level
/// determinism contract.
double combatEffectiveAttackerStrength({
  required double base,
  required int fortLevel,
  double factor1 = 1.0,
  double factor2 = 1.0,
  double factor3 = 1.0,
}) {
  var eff = base * factor1 * factor2 * factor3;
  if (_fortAppliesForCombatModifiers(fortLevel)) {
    eff *= (kUnityAttackerStrengthMultiplier - fortDamageReduction[fortLevel]);
  }
  return eff;
}

/// Defender effective strength: `base × factor1 × factor2 × factor3`, plus
/// [emplacedStrength] when [fortLevel] is in the siege range.
///
/// Factors are applied left-to-right in the listed order; see the module-level
/// determinism contract.
double combatEffectiveDefenderStrength({
  required double base,
  required int fortLevel,
  double factor1 = 1.0,
  double factor2 = 1.0,
  double factor3 = 1.0,
  double emplacedStrength = 0.0,
}) {
  var eff = base * factor1 * factor2 * factor3;
  if (_fortAppliesForCombatModifiers(fortLevel)) {
    eff += emplacedStrength;
  }
  return eff;
}

/// Attacker effective strength used for the casualty ratio after wall HP soak.
///
/// Outside the siege fort range the value is returned unchanged. Within it, wall
/// HP is subtracted and the result clamped to
/// `[clampMin, clampMax]` (defaults match the canonical `[0, ∞)` soak bounds).
double combatEffectiveAttackForRatio({
  required double effAtt,
  required int fortLevel,
  double clampMin = kEffectiveAttackForRatioClampMin,
  double clampMax = kEffectiveAttackForRatioClampMax,
}) {
  if (!_fortAppliesForCombatModifiers(fortLevel)) return effAtt;
  final wallHp = wallHpByFortLevel[fortLevel];
  return (effAtt - wallHp).clamp(clampMin, clampMax);
}

/// Default lump emplaced-gun strength for a fort level (no per-gun HP tracking).
///
/// Returns `0.0` outside the siege fort range. Quick Battle siege resolution
/// passes its own virtual per-gun alive sum instead of this lump.
double combatDefaultEmplacedStrength(int fortLevel) {
  if (!_fortAppliesForCombatModifiers(fortLevel)) return 0.0;
  return fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel];
}
