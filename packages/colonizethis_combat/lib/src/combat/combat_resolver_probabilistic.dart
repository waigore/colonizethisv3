// SPDX-License-Identifier: Apache-2.0

/// Probabilistic multi-round combat resolver for simulation tools.
/// SPEC/program/combat-resolution.md, SPEC/program/sim-combat.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_effective_strength.dart';
import 'combat_rng.dart';
import 'combat_resolver_probabilistic_casualties.dart';
import 'combat_resolver_probabilistic_types.dart';
import 'combat_types.dart';
import 'military_strength.dart';

export 'combat_resolver_probabilistic_types.dart';

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
  final rng = random ?? probabilisticEngagementRng(seed);

  // Keep (copy-disposition, Refs #3448 AC5): the probabilistic simulation
  // mutates unit state across rounds, so it requires detached unit lists
  // (deep copyWith), not the shared ship-list helper.
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
    final effAtt = combatEffectiveAttackerStrength(
      base: rawAtt,
      fortLevel: fortLevel,
      factor1: terrainMod.$1,
      factor2: attackerMoraleMultiplier,
    );
    final effDef = combatEffectiveDefenderStrength(
      base: rawDef,
      fortLevel: fortLevel,
      factor1: terrainMod.$2,
      factor2: defenderMoraleMultiplier,
      emplacedStrength: combatDefaultEmplacedStrength(fortLevel),
    );

    final effAttForRatio = combatEffectiveAttackForRatio(
      effAtt: effAtt,
      fortLevel: fortLevel,
    );

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

    final nDefCas = poissonSample(lambdaDef, rng).clamp(0, defList.length);
    final nAttCas = poissonSample(lambdaAtt, rng).clamp(0, attList.length);

    final defCasIds = selectCasualtiesWeighted(
      defList,
      nDefCas,
      defenderEffectiveMilitaryLevel,
      rng,
    );
    final attCasIds = selectCasualtiesWeighted(attList, nAttCas, 4, rng);

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
