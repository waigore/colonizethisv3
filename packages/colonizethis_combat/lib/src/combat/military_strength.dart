// Copyright 2024 Robert W. Guenther
// SPDX-License-Identifier: Apache-2.0

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

/// Military strength aggregation for display (e.g., Game Overview tab).
/// SPEC/program/military-strength.md.
///
/// This module provides a shared implementation of the military strength
/// aggregation formula used by both the deterministic and probabilistic
/// combat resolvers.

/// Downgrades regiment stats to the specified era by finding a regiment
/// in the same category at the target era.
/// Public for use by combat resolver implementations.
RegimentStats? downgradeToEra(RegimentStats stats, int era) {
  final sameCategory = regimentCatalog
      .where((r) => r.category == stats.category && r.era == era)
      .toList();
  return sameCategory.isNotEmpty ? sameCategory.first : null;
}

/// Computes strength for a single unit using the shared formula.
/// Public so both deterministic and probabilistic resolvers stay in sync.
double unitStrength(Unit u, int effectiveEra) {
  var stats = regimentStatsById(u.type);
  if (stats == null) return 0.0;
  if (stats.era > effectiveEra) {
    stats = downgradeToEra(stats, effectiveEra) ?? stats;
  }
  final mult = medalMultiplierFor(u.medals.clamp(0, 4));
  return (stats.fpn + stats.fpm) * mult;
}

/// Aggregates military strength for a list of units using the given effective
/// era. Uses the same formula as auto-resolve: sum of (FPN+FPM)*medalMultiplier
/// per unit, with era downgrade when unit era exceeds effective era.
/// Public for use by combat resolver implementations.
double aggregateStrength(List<Unit> units, int effectiveEra) {
  var total = 0.0;
  for (final u in units) {
    total += unitStrength(u, effectiveEra);
  }
  return total;
}

/// Morale multiplier from feeding coverage (land or naval). Same breakpoints for
/// army and fleet upkeep shortfall. SPEC/program/turn-resolution-phase-details.md § Consumption.
double moraleMultiplierForFeedingCoverage(double coverage) {
  if (coverage >= 1.0) return 1.0;
  if (coverage >= 0.5) return 0.75;
  return 0.5;
}

/// Computes the effective military level for a faction.
/// Great Powers use era 4; Minor Nations and Tribes use their effectiveMilitaryLevel.
int effectiveEraForFaction(Game game, String factionId) {
  if (game.playerById(factionId) != null) {
    return 4;
  }
  for (final m in game.minorNations) {
    if (m.id == factionId) return m.effectiveMilitaryLevel;
  }
  for (final t in game.tribes) {
    if (t.id == factionId) return t.effectiveMilitaryLevel;
  }
  return 4;
}

/// Aggregates military strength for a faction.
/// Uses the same formula as auto-resolve: sum of (FPN+FPM)*medalMultiplier per unit.
///
/// Spec: SPEC/program/military-strength.md
double aggregateMilitaryStrengthForPlayer(Game game, String playerId) {
  final effectiveEra = effectiveEraForFaction(game, playerId);
  var total = 0.0;
  for (final u in allUnitsFromWorld(game.worldState)) {
    if (u.ownerId != playerId) continue;
    total += unitStrength(u, effectiveEra);
  }
  return total;
}
