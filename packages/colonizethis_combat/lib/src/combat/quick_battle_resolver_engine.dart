part of 'quick_battle_resolver.dart';

List<QuickBattleGroup> _copyGroups(List<QuickBattleGroup> groups) => groups
    .map((g) => g.copyWith(unitIds: List<String>.from(g.unitIds)))
    .toList();

int _rollCommandPoints(Random rng) {
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

List<QuickBattleAction> _limitActionsByCp(
  List<QuickBattleAction> actions,
  int cp,
) {
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

class _ActionModifiers {
  const _ActionModifiers({
    required this.offenseModifier,
    required this.casualtiesDealtModifier,
    required this.casualtiesTakenModifier,
  });

  final double offenseModifier;
  final double casualtiesDealtModifier;
  final double casualtiesTakenModifier;
}

_ActionModifiers _aggregateActionModifiers(List<QuickBattleAction> actions) {
  var offense = 1.0;
  var dealt = 1.0;
  var taken = 1.0;

  for (final a in actions) {
    switch (a) {
      case QuickBattleAction.volleyFire:
        dealt += 0.15;
        break;
      case QuickBattleAction.defendEntrench:
        offense += 0.0;
        taken -= 0.15;
        break;
      case QuickBattleAction.maneuver:
        offense += 0.05;
        break;
      case QuickBattleAction.fallBackRefuseFlank:
        offense -= 0.2;
        taken -= 0.25;
        break;
      case QuickBattleAction.assaultCharge:
        offense += 0.25;
        taken += 0.1;
        break;
    }
  }

  offense = offense.clamp(0.5, 1.5);
  dealt = dealt.clamp(0.5, 1.5);
  taken = taken.clamp(0.5, 1.5);

  return _ActionModifiers(
    offenseModifier: offense,
    casualtiesDealtModifier: dealt,
    casualtiesTakenModifier: taken,
  );
}

double _effectiveStrength(
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

List<String> _pickCasualties(
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

List<QuickBattleGroup> _removeCasualties(
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

List<QuickBattleGroup> _degradeCohesion(List<QuickBattleGroup> groups) {
  return groups
      .map(
        (g) => g.copyWith(
          cohesion: (g.cohesion - 1).clamp(0, quickBattleMaxCohesion),
        ),
      )
      .toList();
}

int _totalUnitCount(List<QuickBattleGroup> groups) =>
    groups.fold(0, (s, g) => s + g.unitIds.length);

bool _attackerActsFirst(QuickBattleInput input) {
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
/// [_attackerEffectiveStrength] and [_defenderEffectiveStrength] and only
/// recompute the side whose state has changed between strikes. This avoids
/// the previous O(4) `_effectiveStrength` invocations per round, where the
/// striker side's strength was identical across both loss-fraction calls.
double _defenderLossFractionFromAttackerStrike({
  required QuickBattleInput input,
  required double effAtt,
  required double effDef,
  required _ActionModifiers attMods,
  required _ActionModifiers defMods,
}) {
  final wallHp = input.fortLevel >= 1 && input.fortLevel <= 3
      ? wallHpByFortLevel[input.fortLevel]
      : 0.0;
  final effAttForRatio = (effAtt - wallHp).clamp(0.0, double.infinity);
  final ratio = effDef > 0 ? effAttForRatio / effDef : 10.0;
  return (_targetLossFraction(ratio) *
          attMods.casualtiesDealtModifier *
          defMods.casualtiesTakenModifier)
      .clamp(0.0, 1.0);
}

/// Computes the attacker loss fraction from a defender strike using
/// precomputed effective strengths. See [_defenderLossFractionFromAttackerStrike]
/// for the round-level caching contract.
double _attackerLossFractionFromDefenderStrike({
  required double effAtt,
  required double effDef,
  required _ActionModifiers attMods,
  required _ActionModifiers defMods,
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

double _attackerEffectiveStrength({
  required QuickBattleInput input,
  required List<QuickBattleGroup> attGroups,
  required _ActionModifiers attMods,
}) {
  final terrainMod = terrainModifiers[input.provinceTerrain] ?? (1.0, 1.0);
  var effAtt =
      _effectiveStrength(attGroups, input.attackerDeployment.laneTerrain) *
      attMods.offenseModifier *
      input.attackerLeaderMultiplier *
      terrainMod.$1;
  if (input.fortLevel >= 1 && input.fortLevel <= 3) {
    effAtt *= (1.0 - fortDamageReduction[input.fortLevel]);
  }
  return effAtt;
}

double _defenderEffectiveStrength({
  required QuickBattleInput input,
  required List<QuickBattleGroup> defGroups,
  required _ActionModifiers defMods,
  required List<_MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  final terrainMod = terrainModifiers[input.provinceTerrain] ?? (1.0, 1.0);
  var effDef =
      _effectiveStrength(defGroups, input.defenderDeployment.laneTerrain) *
      defMods.offenseModifier *
      input.defenderLeaderMultiplier *
      terrainMod.$2;
  if (input.fortLevel >= 1 && input.fortLevel <= 3) {
    if (useVirtualEmplaced) {
      effDef += _aliveGunStrengthSum(mutableGuns);
    } else {
      effDef +=
          fortGunCount[input.fortLevel] * fortEmplacedStrength[input.fortLevel];
    }
  }
  return effDef;
}

List<String> _pickDefenderLosses({
  required List<QuickBattleGroup> groups,
  required double fraction,
  required Random rng,
  required List<_MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  if (!useVirtualEmplaced) return _pickCasualties(groups, fraction, rng);
  final regimentCount = _totalUnitCount(groups);
  final gunHpPool = _sumAliveGunHp(mutableGuns);
  final totalSlots = regimentCount + gunHpPool;
  final gunHpLoss = totalSlots > 0 && gunHpPool > 0
      ? min(gunHpPool, max(0, (fraction * gunHpPool).round()))
      : 0;
  _applyRoundRobinGunHpDamage(mutableGuns, gunHpLoss);
  final regFrac = regimentCount > 0 && totalSlots > 0
      ? (fraction * regimentCount / totalSlots).clamp(0.0, 1.0)
      : 0.0;
  return _pickCasualties(groups, regFrac, rng);
}
