// SPDX-License-Identifier: Apache-2.0

/// Result types and constants for probabilistic combat resolution.
/// SPEC/program/combat-resolution.md, SPEC/program/sim-combat.md.
library;

import 'combat_types.dart';

/// Maximum number of combat rounds per engagement.
const int maxCombatRounds = 5;

/// Lethality factor: expected casualties per round scale.
const double combatLethalityK = 1.0;

/// Hit probability clamp [min, max].
const double hitProbabilityMin = 0.15;
const double hitProbabilityMax = 0.85;

/// Result of one round in probabilistic combat.
class ProbabilisticRoundResult {
  const ProbabilisticRoundResult({
    required this.roundNumber,
    required this.rawAttackerStrength,
    required this.rawDefenderStrength,
    required this.effectiveAttackerStrength,
    required this.effectiveDefenderStrength,
    required this.probabilityAttackerHits,
    required this.probabilityDefenderHits,
    required this.lambdaDefender,
    required this.lambdaAttacker,
    required this.defenderCasualties,
    required this.attackerCasualties,
    required this.attackersRemaining,
    required this.defendersRemaining,
  });

  final int roundNumber;
  final double rawAttackerStrength;
  final double rawDefenderStrength;
  final double effectiveAttackerStrength;
  final double effectiveDefenderStrength;
  final double probabilityAttackerHits;
  final double probabilityDefenderHits;
  final double lambdaDefender;
  final double lambdaAttacker;
  final List<String> defenderCasualties;
  final List<String> attackerCasualties;
  final int attackersRemaining;
  final int defendersRemaining;
}

/// Result of probabilistic engagement with per-round details.
class ProbabilisticEngagementOutcome {
  const ProbabilisticEngagementOutcome({
    required this.result,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.attackerStrength,
    required this.defenderStrength,
    required this.rounds,
  });

  final EngagementResult result;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final double attackerStrength;
  final double defenderStrength;
  final List<ProbabilisticRoundResult> rounds;
}
