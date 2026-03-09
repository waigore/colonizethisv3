import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/fog_resolution.dart';
import 'conflict_detection.dart';

/// Quick Battle resolution pipeline. SPEC/program/quick-battle-resolution.md.
/// Deterministic for given seed; output feeds same casualty/flip pipeline as auto-resolve.

/// Resolves a Quick Battle to completion. Uses [roundActions] if provided; otherwise
/// applies default deterministic actions (Volley Fire each round) for AI/simulation.
QuickBattleResult resolveQuickBattle(
  QuickBattleInput input, {
  List<QuickBattleRoundActions>? roundActions,
}) {
  final rng = Random(input.seed);
  var attGroups = _copyGroups(input.attackerDeployment.groups);
  var defGroups = _copyGroups(input.defenderDeployment.groups);
  final attCasualties = <String>[];
  final defCasualties = <String>[];

  for (var round = 1; round <= input.maxRounds; round++) {
    // Determine command points for this round (2–3 per side per spec).
    final attCp = _rollCommandPoints(rng);
    final defCp = _rollCommandPoints(rng);

    // Default: Volley Fire for both sides if no actions provided.
    final rawAttActs = roundActions != null && round <= roundActions.length
        ? roundActions[round - 1].actions
        : const [QuickBattleAction.volleyFire];
    final rawDefActs = roundActions != null && round <= roundActions.length
        ? roundActions[round - 1].actions
        : const [QuickBattleAction.volleyFire];

    final attActs = _limitActionsByCp(rawAttActs, attCp);
    final defActs = _limitActionsByCp(rawDefActs, defCp);

    // Compute per-side action modifiers (offense/defense and casualty effects).
    final attMods = _aggregateActionModifiers(attActs);
    final defMods = _aggregateActionModifiers(defActs);

    // Compute effective strengths per side from groups and terrain.
    var attStr =
        _effectiveStrength(attGroups, input.attackerDeployment.laneTerrain) *
            attMods.offenseModifier *
            input.attackerLeaderMultiplier;
    var defStr =
        _effectiveStrength(defGroups, input.defenderDeployment.laneTerrain) *
            defMods.offenseModifier *
            input.defenderLeaderMultiplier;

    // Apply terrain and fort modifiers (same as combat_resolver).
    final terrainMod = terrainModifiers[input.provinceTerrain] ?? (1.0, 1.0);
    var effAtt = attStr * terrainMod.$1;
    var effDef = defStr * terrainMod.$2;
    if (input.fortLevel >= 1 && input.fortLevel <= 3) {
      final reduction = fortDamageReduction[input.fortLevel];
      effAtt *= (1.0 - reduction);
      final emplaced = fortGunCount[input.fortLevel] * fortEmplacedStrength[input.fortLevel];
      effDef += emplaced;
    }

    var effAttForRatio = effAtt;
    if (input.fortLevel >= 1 && input.fortLevel <= 3) {
      final wallHp = wallHpByFortLevel[input.fortLevel];
      effAttForRatio = (effAtt - wallHp).clamp(0.0, double.infinity);
    }

    // Round casualties using strength ratio (deterministic from seed).
    final ratio = effDef > 0 ? effAttForRatio / effDef : 10.0;
    var attLossFraction = 0.4;
    var defLossFraction = 0.4;
    if (ratio >= 1.5) {
      defLossFraction = 0.85;
      attLossFraction = 0.15;
    } else if (ratio <= 0.67) {
      attLossFraction = 0.85;
      defLossFraction = 0.15;
    }

    // Apply action-based casualty modifiers.
    defLossFraction =
        (defLossFraction * attMods.casualtiesDealtModifier * defMods.casualtiesTakenModifier)
            .clamp(0.0, 1.0);
    attLossFraction =
        (attLossFraction * defMods.casualtiesDealtModifier * attMods.casualtiesTakenModifier)
            .clamp(0.0, 1.0);

    final defLoss = _pickCasualties(defGroups, defLossFraction, rng);
    defCasualties.addAll(defLoss);
    defGroups = _removeCasualties(defGroups, defLoss);
    final attLoss = _pickCasualties(attGroups, attLossFraction, rng);
    attCasualties.addAll(attLoss);
    attGroups = _removeCasualties(attGroups, attLoss);

    // Simple cohesion model: side taking heavier losses loses cohesion.
    if (defLoss.length > attLoss.length && defLoss.isNotEmpty) {
      defGroups = _degradeCohesion(defGroups);
    } else if (attLoss.length > defLoss.length && attLoss.isNotEmpty) {
      attGroups = _degradeCohesion(attGroups);
    }

    // Early exit if one side eliminated.
    if (_totalUnitCount(defGroups) <= 0) {
      return QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: attCasualties,
        defenderCasualties: defCasualties,
        provinceFlips: true,
      );
    }
    if (_totalUnitCount(attGroups) <= 0) {
      return QuickBattleResult(
        winner: QuickBattleWinner.defender,
        attackerCasualties: attCasualties,
        defenderCasualties: defCasualties,
        provinceFlips: false,
      );
    }
  }

  // After max rounds: decide by remaining strength (leader multipliers already applied in-round).
  final finalAttStr = _effectiveStrength(attGroups, input.attackerDeployment.laneTerrain) *
      input.attackerLeaderMultiplier;
  final finalDefStr = _effectiveStrength(defGroups, input.defenderDeployment.laneTerrain) *
      input.defenderLeaderMultiplier;
  if (finalAttStr > finalDefStr * 1.2) {
    return QuickBattleResult(
      winner: QuickBattleWinner.attacker,
      attackerCasualties: attCasualties,
      defenderCasualties: defCasualties,
      provinceFlips: true,
    );
  }
  if (finalDefStr > finalAttStr * 1.2) {
    return QuickBattleResult(
      winner: QuickBattleWinner.defender,
      attackerCasualties: attCasualties,
      defenderCasualties: defCasualties,
      provinceFlips: false,
    );
  }
  return QuickBattleResult(
    winner: QuickBattleWinner.mutualExhaustion,
    attackerCasualties: attCasualties,
    defenderCasualties: defCasualties,
    provinceFlips: false,
  );
}

List<QuickBattleGroup> _copyGroups(List<QuickBattleGroup> groups) =>
    groups.map((g) => g.copyWith(unitIds: List<String>.from(g.unitIds))).toList();

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

  // Clamp to reasonable ranges.
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
      .map((g) => g.copyWith(
            unitIds: g.unitIds.where((id) => !casualtySet.contains(id)).toList(),
          ))
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

/// Applies QuickBattleResult to Game: remove casualties, flip province if winner is attacker.
Game applyQuickBattleResultToGame(
  Game game,
  BattleContext ctx,
  QuickBattleResult result,
) {
  final region = ctx.regionId == kRegionOldWorld
      ? game.worldState.oldWorld
      : game.worldState.newWorld;
  final casualtySet = {
    ...result.attackerCasualties,
    ...result.defenderCasualties,
  };
  final survivingUnits =
      region.units.where((u) => !casualtySet.contains(u.id)).toList();

  var provinces = region.provinces;
  if (result.provinceFlips &&
      result.winner == QuickBattleWinner.attacker &&
      ctx.attackers.isNotEmpty) {
    final attackerFactionId = ctx.attackers.first.factionId;
    final idx = provinces.indexWhere((p) => p.id == ctx.provinceId);
    if (idx >= 0) {
      provinces = List.from(provinces)
        ..[idx] = provinces[idx].copyWith(ownerId: attackerFactionId);
    }
  }

  final newRegion = RegionData(
    provinces: provinces,
    units: survivingUnits,
  );
  WorldState newWorldState;
  if (ctx.regionId == kRegionOldWorld) {
    newWorldState = game.worldState.copyWith(oldWorld: newRegion);
  } else {
    newWorldState = game.worldState.copyWith(newWorld: newRegion);
  }

  // When Quick Battle flips a province, clear Spy timers for (attacker, that province)
  // so that own provinces never decay via Spy timers.
  if (result.provinceFlips &&
      result.winner == QuickBattleWinner.attacker &&
      ctx.attackers.isNotEmpty) {
    final attackerFactionId = ctx.attackers.first.factionId;
    final timers = clearSpyRevealTimersForProvince(
      game.worldState.spyRevealTurnsByPlayer,
      attackerFactionId,
      ctx.provinceId,
    );
    newWorldState = newWorldState.copyWith(spyRevealTurnsByPlayer: timers);
  }

  return game.copyWith(worldState: newWorldState);
}
