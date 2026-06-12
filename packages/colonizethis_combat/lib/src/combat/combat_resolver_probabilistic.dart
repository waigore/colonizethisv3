// SPDX-License-Identifier: Apache-2.0

/// Probabilistic multi-round combat resolver for simulation tools.
/// SPEC/program/combat-resolution.md, SPEC/program/sim-combat.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_types.dart';
import 'military_strength.dart';

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

/// Resolves one engagement probabilistically (up to [maxCombatRounds] rounds).
/// Uses clamped hit odds, Poisson-sampled casualties, and strength-weighted
/// casualty selection (stronger units less likely to die).
///
/// Pass [random] for control, or use [seed] to build a Random. Same seed
/// produces identical outcome.
ProbabilisticEngagementOutcome resolveEngagementProbabilistic({
  required List<Unit> attackerUnits,
  required List<Unit> defenderUnits,
  int generalMedals = 0,
  required int fortLevel,
  required String terrain,
  int defenderEffectiveMilitaryLevel = 4,
  Random? random,
  int? seed,
  double attackerMoraleMultiplier = 1.0,
  double defenderMoraleMultiplier = 1.0,
}) {
  final rng = random ?? Random(seed ?? 0);

  var attList = attackerUnits.map((u) => u.copyWith()).toList();
  var defList = defenderUnits.map((u) => u.copyWith()).toList();

  final allAttackerCasualties = <String>[];
  final allDefenderCasualties = <String>[];
  final roundResults = <ProbabilisticRoundResult>[];

  final initialAttStr = aggregateStrength(attackerUnits, 4);
  final initialDefStr = aggregateStrength(
    defenderUnits,
    defenderEffectiveMilitaryLevel,
  );

  for (var round = 1; round <= maxCombatRounds; round++) {
    if (attList.isEmpty || defList.isEmpty) break;

    final rawAtt = aggregateStrength(attList, 4);
    final rawDef = aggregateStrength(defList, defenderEffectiveMilitaryLevel);

    final terrainMod = terrainModifiers[terrain] ?? (1.0, 1.0);
    var effAtt = rawAtt * terrainMod.$1 * attackerMoraleMultiplier;
    var effDef = rawDef * terrainMod.$2 * defenderMoraleMultiplier;

    if (fortLevel >= 1 && fortLevel <= 3) {
      final reduction = fortDamageReduction[fortLevel];
      effAtt *= (1.0 - reduction);
      final emplaced =
          fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel];
      effDef += emplaced;
    }

    var effAttForRatio = effAtt;
    if (fortLevel >= 1 && fortLevel <= 3) {
      final wallHp = wallHpByFortLevel[fortLevel];
      effAttForRatio = (effAtt - wallHp).clamp(0.0, double.infinity);
    }

    final total = effAttForRatio + effDef;
    double pAtt = 0.5;
    double pDef = 0.5;
    if (total > 0) {
      pAtt = (effAttForRatio / total).clamp(
        hitProbabilityMin,
        hitProbabilityMax,
      );
      pDef = (effDef / total).clamp(hitProbabilityMin, hitProbabilityMax);
    }

    final lambdaDef = combatLethalityK * pAtt;
    final lambdaAtt = combatLethalityK * pDef;

    final nDefCas = _poissonSample(lambdaDef, rng).clamp(0, defList.length);
    final nAttCas = _poissonSample(lambdaAtt, rng).clamp(0, attList.length);

    final defCasIds = _selectCasualtiesWeighted(
      defList,
      nDefCas,
      defenderEffectiveMilitaryLevel,
      rng,
    );
    final attCasIds = _selectCasualtiesWeighted(attList, nAttCas, 4, rng);

    for (final id in defCasIds) {
      defList = defList.where((u) => u.id != id).toList();
      allDefenderCasualties.add(id);
    }
    for (final id in attCasIds) {
      attList = attList.where((u) => u.id != id).toList();
      allAttackerCasualties.add(id);
    }

    roundResults.add(
      ProbabilisticRoundResult(
        roundNumber: round,
        rawAttackerStrength: rawAtt,
        rawDefenderStrength: rawDef,
        effectiveAttackerStrength: effAtt,
        effectiveDefenderStrength: effDef,
        probabilityAttackerHits: pAtt,
        probabilityDefenderHits: pDef,
        lambdaDefender: lambdaDef,
        lambdaAttacker: lambdaAtt,
        defenderCasualties: defCasIds,
        attackerCasualties: attCasIds,
        attackersRemaining: attList.length,
        defendersRemaining: defList.length,
      ),
    );

    if (attList.isEmpty || defList.isEmpty) break;
  }

  EngagementResult result;
  if (attList.isEmpty && defList.isEmpty) {
    result = EngagementResult.mutualAnnihilation;
  } else if (defList.isEmpty) {
    result = EngagementResult.attackerVictory;
  } else if (attList.isEmpty) {
    result = EngagementResult.defenderVictory;
  } else {
    result = EngagementResult.stalemate;
  }

  return ProbabilisticEngagementOutcome(
    result: result,
    attackerCasualties: allAttackerCasualties,
    defenderCasualties: allDefenderCasualties,
    attackerStrength: initialAttStr,
    defenderStrength: initialDefStr,
    rounds: roundResults,
  );
}

int _poissonSample(double lambda, Random rng) {
  if (lambda <= 0) return 0;
  final L = exp(-lambda);
  var k = 0;
  var p = 1.0;
  do {
    k++;
    p *= rng.nextDouble();
    if (p <= 0) return k - 1;
  } while (p > L);
  return k - 1;
}

/// Select [n] casualties using inverse-strength weighting (stronger = less likely).
List<String> _selectCasualtiesWeighted(
  List<Unit> units,
  int n,
  int effectiveEra,
  Random rng,
) {
  if (n <= 0 || units.isEmpty) return [];
  if (n >= units.length) return units.map((u) => u.id).toList();

  final weights = <double>[];
  for (final u in units) {
    final s = unitStrength(u, effectiveEra);
    weights.add(1.0 / (s + 0.1));
  }
  final ids = units.map((u) => u.id).toList();
  final alive = List<bool>.filled(ids.length, true);
  final chosen = <String>[];

  for (var i = 0; i < n; i++) {
    var total = 0.0;
    for (var j = 0; j < weights.length; j++) {
      if (alive[j]) total += weights[j];
    }
    if (total <= 0) break;
    var r = rng.nextDouble() * total;
    for (var j = 0; j < weights.length; j++) {
      if (!alive[j]) continue;
      r -= weights[j];
      if (r <= 0) {
        chosen.add(ids[j]);
        alive[j] = false;
        break;
      }
    }
  }
  return chosen;
}
