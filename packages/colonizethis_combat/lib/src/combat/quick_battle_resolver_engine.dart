/// Quick Battle round-engine helpers: group bookkeeping, command-point limits,
/// effective-strength and casualty-fraction math.
///
/// SPEC/program/quick-battle-resolution.md.
///
/// Extracted from the `quick_battle_resolver.dart` part-file group into a
/// regular library so these helpers can be imported (and unit-tested)
/// independently. Helpers consumed by the resolver are package-public; helpers
/// used only within this file remain private.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_effective_strength.dart';
import 'quick_battle_action_modifiers.dart';
import 'quick_battle_emplaced_guns.dart';

List<QuickBattleGroup> copyGroups(List<QuickBattleGroup> groups) => groups
    .map((g) => g.copyWith(unitIds: List<String>.from(g.unitIds)))
    .toList();

int rollCommandPoints(Random rng) {
  final span = quickBattleCpPerRoundMax - quickBattleCpPerRoundMin;
  if (span <= 0) return quickBattleCpPerRoundMin;
  return quickBattleCpPerRoundMin + rng.nextInt(span + 1);
}

int _actionCost(QuickBattleAction action) {
  switch (action) {
    case QuickBattleAction.volleyFire:
    case QuickBattleAction.defendEntrench:
    case QuickBattleAction.maneuver:
      return 1;
    case QuickBattleAction.fallBackRefuseFlank:
    case QuickBattleAction.assaultCharge:
      return 2;
  }
}

List<QuickBattleAction> limitActionsByCp(List<QuickBattleAction> actions, int cp) {
  final result = <QuickBattleAction>[];
  var spent = 0;
  for (final a in actions) {
    final cost = _actionCost(a);
    if (spent + cost > cp) break;
    result.add(a);
    spent += cost;
  }
  return result;
}

double effectiveStrength(
  List<QuickBattleGroup> groups,
  Map<String, QuickBattleLaneTerrain> laneTerrain,
) {
  var total = 0.0;
  for (final g in groups) {
    if (g.unitIds.isEmpty || g.cohesion <= 0) continue;
    final cohesionScale = g.cohesion / quickBattleMaxCohesion;
    final terrainKey = '${g.lane.name}_${g.line.name}';
    final terr = laneTerrain[terrainKey] ?? QuickBattleLaneTerrain.open;
    var mod = 1.0;
    switch (terr) {
      case QuickBattleLaneTerrain.hill:
      case QuickBattleLaneTerrain.town:
        mod = 1.1;
        break;
      case QuickBattleLaneTerrain.woods:
        mod = 0.95;
        break;
      case QuickBattleLaneTerrain.swamp:
        mod = 0.8;
        break;
      case QuickBattleLaneTerrain.open:
        break;
    }
    total += g.unitIds.length * cohesionScale * mod;
  }
  return total;
}

List<String> pickCasualties(
  List<QuickBattleGroup> groups,
  double fraction,
  Random rng,
) {
  final allIds = <String>[];
  for (final g in groups) {
    allIds.addAll(g.unitIds);
  }
  if (allIds.isEmpty) return [];
  final count = (allIds.length * fraction).ceil().clamp(0, allIds.length);
  allIds.shuffle(rng);
  return allIds.take(count).toList();
}

List<QuickBattleGroup> removeCasualties(
  List<QuickBattleGroup> groups,
  List<String> casualties,
) {
  final casualtySet = casualties.toSet();
  return groups
      .map(
        (g) => g.copyWith(
          unitIds: g.unitIds.where((id) => !casualtySet.contains(id)).toList(),
        ),
      )
      .where((g) => g.unitIds.isNotEmpty)
      .toList();
}

List<QuickBattleGroup> degradeCohesion(List<QuickBattleGroup> groups) {
  return groups
      .map(
        (g) => g.copyWith(
          cohesion: (g.cohesion - 1).clamp(0, quickBattleMaxCohesion),
        ),
      )
      .toList();
}

int totalUnitCount(List<QuickBattleGroup> groups) =>
    groups.fold(0, (s, g) => s + g.unitIds.length);

bool attackerActsFirst(QuickBattleInput input) {
  final attackerInitiative =
      input.attackerCavalryShare * initiativeCavalryShareWeight +
      input.attackerGeneralMedals * initiativeGeneralMedalWeight;
  final defenderInitiative =
      input.defenderCavalryShare * initiativeCavalryShareWeight +
      input.defenderGeneralMedals * initiativeGeneralMedalWeight;
  if (attackerInitiative != defenderInitiative) {
    return attackerInitiative > defenderInitiative;
  }
  return input.attackerFactionId.compareTo(input.defenderFactionId) < 0;
}

/// Computes the defender loss fraction from an attacker strike using
/// precomputed effective strengths.
///
/// Callers compute `effAtt` and `effDef` once at the round level via
/// [attackerEffectiveStrength] and [defenderEffectiveStrength] and only
/// recompute the side whose state has changed between strikes. This avoids
/// the previous O(4) [effectiveStrength] invocations per round, where the
/// striker side's strength was identical across both loss-fraction calls.
double defenderLossFractionFromAttackerStrike({
  required QuickBattleInput input,
  required double effAtt,
  required double effDef,
  required ActionModifiers attMods,
  required ActionModifiers defMods,
}) {
  final effAttForRatio = combatEffectiveAttackForRatio(
    effAtt: effAtt,
    fortLevel: input.fortLevel,
  );
  final ratio = effDef > 0 ? effAttForRatio / effDef : 10.0;
  return (_targetLossFraction(ratio) *
          attMods.casualtiesDealtModifier *
          defMods.casualtiesTakenModifier)
      .clamp(0.0, 1.0);
}

/// Computes the attacker loss fraction from a defender strike using
/// precomputed effective strengths. See [defenderLossFractionFromAttackerStrike]
/// for the round-level caching contract.
double attackerLossFractionFromDefenderStrike({
  required double effAtt,
  required double effDef,
  required ActionModifiers attMods,
  required ActionModifiers defMods,
}) {
  final ratio = effAtt > 0 ? effDef / effAtt : 10.0;
  return (_targetLossFraction(ratio) *
          defMods.casualtiesDealtModifier *
          attMods.casualtiesTakenModifier)
      .clamp(0.0, 1.0);
}

double _targetLossFraction(double strikerToTargetRatio) {
  if (strikerToTargetRatio >= 1.5) return 0.85;
  if (strikerToTargetRatio <= 0.67) return 0.15;
  return 0.4;
}

double attackerEffectiveStrength({
  required QuickBattleInput input,
  required List<QuickBattleGroup> attGroups,
  required ActionModifiers attMods,
}) {
  final terrainMod = terrainModifiers[input.provinceTerrain] ?? (1.0, 1.0);
  return combatEffectiveAttackerStrength(
    base: effectiveStrength(attGroups, input.attackerDeployment.laneTerrain),
    fortLevel: input.fortLevel,
    factor1: attMods.offenseModifier,
    factor2: input.attackerLeaderMultiplier,
    factor3: terrainMod.$1,
  );
}

double defenderEffectiveStrength({
  required QuickBattleInput input,
  required List<QuickBattleGroup> defGroups,
  required ActionModifiers defMods,
  required List<MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  final terrainMod = terrainModifiers[input.provinceTerrain] ?? (1.0, 1.0);
  final emplaced = useVirtualEmplaced
      ? aliveGunStrengthSum(mutableGuns)
      : combatDefaultEmplacedStrength(input.fortLevel);
  return combatEffectiveDefenderStrength(
    base: effectiveStrength(defGroups, input.defenderDeployment.laneTerrain),
    fortLevel: input.fortLevel,
    factor1: defMods.offenseModifier,
    factor2: input.defenderLeaderMultiplier,
    factor3: terrainMod.$2,
    emplacedStrength: emplaced,
  );
}

List<String> pickDefenderLosses({
  required List<QuickBattleGroup> groups,
  required double fraction,
  required Random rng,
  required List<MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  if (!useVirtualEmplaced) return pickCasualties(groups, fraction, rng);
  final regimentCount = totalUnitCount(groups);
  final gunHpPool = sumAliveGunHp(mutableGuns);
  final totalSlots = regimentCount + gunHpPool;
  final gunHpLoss = totalSlots > 0 && gunHpPool > 0
      ? min(gunHpPool, max(0, (fraction * gunHpPool).round()))
      : 0;
  applyRoundRobinGunHpDamage(mutableGuns, gunHpLoss);
  final regFrac = regimentCount > 0 && totalSlots > 0
      ? (fraction * regimentCount / totalSlots).clamp(0.0, 1.0)
      : 0.0;
  return pickCasualties(groups, regFrac, rng);
}
