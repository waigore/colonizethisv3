// SPDX-License-Identifier: Apache-2.0

/// Deterministic single-engagement strength ratio and casualty resolution.
/// SPEC/program/combat-resolution.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_constants.dart';
import 'combat_effective_strength.dart';
import 'combat_loss_profile.dart';
import 'combat_types.dart';
import 'military_strength.dart';

/// Resolves one engagement: attacker vs defender.
/// SPEC/program/combat-resolution.md.
EngagementOutcome resolveEngagement({
  required List<Unit> attackerUnits,
  required List<Unit> defenderUnits,
  int generalMedals = 0,
  required int fortLevel,
  required String terrain,
  int defenderEffectiveMilitaryLevel = kDefaultEffectiveMilitaryEra,
  double attackerMoraleMultiplier = kNeutralMoraleMultiplier,
  double defenderMoraleMultiplier = kNeutralMoraleMultiplier,
  double attackerLeaderMultiplier = kNeutralLeaderMultiplier,
  double defenderLeaderMultiplier = kNeutralLeaderMultiplier,
}) {
  final attStr = aggregateStrength(attackerUnits, kDefaultEffectiveMilitaryEra);
  var defStr = aggregateStrength(defenderUnits, defenderEffectiveMilitaryLevel);

  final terrainMod =
      terrainModifiers[terrain] ??
      (kNeutralTerrainAttackerModifier, kNeutralTerrainDefenderModifier);
  final effAtt = combatEffectiveAttackerStrength(
    base: attStr,
    fortLevel: fortLevel,
    factor1: terrainMod.$1,
    factor2: attackerMoraleMultiplier,
    factor3: attackerLeaderMultiplier,
  );
  final effDef = combatEffectiveDefenderStrength(
    base: defStr,
    fortLevel: fortLevel,
    factor1: terrainMod.$2,
    factor2: defenderMoraleMultiplier,
    factor3: defenderLeaderMultiplier,
    emplacedStrength: combatDefaultEmplacedStrength(fortLevel),
  );

  // Wall HP soaks damage before it applies to defender casualty ratio. SPEC/game/siege-mechanics.md.
  final effAttForRatio = combatEffectiveAttackForRatio(
    effAtt: effAtt,
    fortLevel: fortLevel,
  );

  final attackerCasualties = <String>[];
  final defenderCasualties = <String>[];

  if (effAttForRatio <= 0 && effDef <= 0) {
    return EngagementOutcome(
      result: EngagementResult.stalemate,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  final ratio = effDef > 0 ? effAttForRatio / effDef : kNoDefenderRatioFallback;
  final attackerLowMorale = attackerMoraleMultiplier < defenderMoraleMultiplier;

  return _resolveByRatio(
    ratio: ratio,
    attackerLowMorale: attackerLowMorale,
    attackerUnits: attackerUnits,
    defenderUnits: defenderUnits,
    attStr: attStr,
    defStr: defStr,
  );
}

EngagementOutcome _resolveByRatio({
  required double ratio,
  required bool attackerLowMorale,
  required List<Unit> attackerUnits,
  required List<Unit> defenderUnits,
  required double attStr,
  required double defStr,
}) {
  final profile = combatLossProfileForStrengthRatio(
    attackerDefenderStrengthRatio: ratio,
    attackerLowMorale: attackerLowMorale,
  );
  return _buildOutcome(
    attackerUnits: attackerUnits,
    defenderUnits: defenderUnits,
    attLossFrac: profile.attackerLossFraction,
    defLossFrac: profile.defenderLossFraction,
    attStr: attStr,
    defStr: defStr,
    bluntAttackerVictory: profile.bluntsAttackerVictory,
    bothDeadResult: _engagementResultForMutualElimination(
      profile.mutualEliminationOutcome,
    ),
  );
}

EngagementResult _engagementResultForMutualElimination(
  CombatMutualEliminationOutcome outcome,
) {
  return switch (outcome) {
    CombatMutualEliminationOutcome.attackerVictory =>
      EngagementResult.attackerVictory,
    CombatMutualEliminationOutcome.defenderVictory =>
      EngagementResult.defenderVictory,
    CombatMutualEliminationOutcome.mutualAnnihilation =>
      EngagementResult.mutualAnnihilation,
  };
}

EngagementOutcome _buildOutcome({
  required List<Unit> attackerUnits,
  required List<Unit> defenderUnits,
  required double attLossFrac,
  required double defLossFrac,
  required double attStr,
  required double defStr,
  bool bluntAttackerVictory = false,
  EngagementResult bothDeadResult = EngagementResult.mutualAnnihilation,
}) {
  final attLoss = combatCasualtyCount(
    unitCount: attackerUnits.length,
    lossFraction: attLossFrac,
  );
  final defLoss = combatCasualtyCount(
    unitCount: defenderUnits.length,
    lossFraction: defLossFrac,
  );

  final attackerCasualties = [
    for (var i = 0; i < attLoss; i++) attackerUnits[i].id,
  ];
  final defenderCasualties = [
    for (var i = 0; i < defLoss; i++) defenderUnits[i].id,
  ];

  final attSurvivors = attackerUnits.length - attLoss;
  final defSurvivors = defenderUnits.length - defLoss;

  EngagementResult result;
  if (attSurvivors <= 0 && defSurvivors <= 0) {
    result = bothDeadResult;
  } else if (attSurvivors <= 0) {
    result = EngagementResult.defenderVictory;
  } else if (defSurvivors <= 0) {
    result = bluntAttackerVictory
        ? EngagementResult.stalemate
        : EngagementResult.attackerVictory;
  } else {
    result = EngagementResult.stalemate;
  }

  return EngagementOutcome(
    result: result,
    attackerCasualties: attackerCasualties,
    defenderCasualties: defenderCasualties,
    attackerStrength: attStr,
    defenderStrength: defStr,
  );
}
