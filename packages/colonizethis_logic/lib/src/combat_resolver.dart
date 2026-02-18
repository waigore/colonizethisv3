import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'conflict_detection.dart';

/// Result of one engagement. SPEC/game/combat.md.
enum EngagementResult {
  attackerVictory,
  defenderVictory,
  stalemate,
  mutualAnnihilation,
}

/// Result of resolving one engagement. SPEC/program/combat-resolution.md.
class EngagementOutcome {
  const EngagementOutcome({
    required this.result,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.attackerStrength,
    required this.defenderStrength,
  });

  final EngagementResult result;
  final List<String> attackerCasualties;
  final List<String> defenderCasualties;
  final double attackerStrength;
  final double defenderStrength;
}

/// Resolves one battle context and returns updated Game state.
/// SPEC/program/combat-resolution.md.
Game resolveBattleContext(
  Game game,
  BattleContext ctx, {
  Map<String, double> feedingCoverageByPlayerId = const {},
}) {
  RegionData region;
  if (ctx.regionId == 'oldWorld') {
    region = game.worldState.oldWorld;
  } else {
    region = game.worldState.newWorld;
  }

  final unitsById = {for (final u in region.units) u.id: u};
  var defenderUnitIds = ctx.defenderUnitIds.toList();
  var defenderFactionId = ctx.defenderFactionId;
  var provinceOwnerId = ctx.defenderFactionId;

  var sortedAttackers = ctx.attackers.toList();
  _sortAttackersByInitiative(sortedAttackers, region.units, unitsById);

  final allCasualties = <String>[];
  String? survivingAttackerFactionId;

  final initialDefenderCount = ctx.defenderUnitIds.length;

  for (final attacker in sortedAttackers) {
    if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
      break;
    }

    final attackerUnits = attacker.unitIds
        .map((id) => unitsById[id])
        .whereType<Unit>()
        .where((u) => !allCasualties.contains(u.id))
        .toList();

    if (attackerUnits.isEmpty) continue;

    final defenderUnits = defenderUnitIds
        .map((id) => unitsById[id])
        .whereType<Unit>()
        .where((u) => !allCasualties.contains(u.id))
        .toList();

    if (defenderUnits.isEmpty) {
      survivingAttackerFactionId = attacker.factionId;
      break;
    }

    final defenderEffectiveLevel = _defenderEffectiveLevel(game, defenderFactionId);
    final attackerCoverage =
        feedingCoverageByPlayerId[attacker.factionId] ?? 1.0;
    final defenderCoverage =
        feedingCoverageByPlayerId[defenderFactionId] ?? 1.0;
    final outcome = resolveEngagement(
      attackerUnits: attackerUnits,
      defenderUnits: defenderUnits,
      generalMedals: attacker.generalMedals,
      fortLevel: ctx.fortLevel,
      terrain: ctx.terrain,
      defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
      attackerMoraleMultiplier: _moraleMultiplierForCoverage(attackerCoverage),
      defenderMoraleMultiplier: _moraleMultiplierForCoverage(defenderCoverage),
    );

    for (final id in outcome.attackerCasualties) {
      allCasualties.add(id);
    }
    for (final id in outcome.defenderCasualties) {
      allCasualties.add(id);
    }

    defenderUnitIds =
        defenderUnits.map((u) => u.id).where((id) => !outcome.defenderCasualties.contains(id)).toList();

    switch (outcome.result) {
      case EngagementResult.attackerVictory:
        survivingAttackerFactionId = attacker.factionId;
        defenderFactionId = attacker.factionId;
        provinceOwnerId = attacker.factionId;
        break;
      case EngagementResult.defenderVictory:
        survivingAttackerFactionId = null;
        break;
      case EngagementResult.stalemate:
        break;
      case EngagementResult.mutualAnnihilation:
        defenderFactionId = provinceOwnerId;
        survivingAttackerFactionId = null;
        final remainingAttackers = sortedAttackers
            .skip(sortedAttackers.indexOf(attacker) + 1)
            .toList();
        if (remainingAttackers.isNotEmpty) {
          final recoverCount =
              (initialDefenderCount * 0.2).ceil().clamp(1, initialDefenderCount);
          final garrisonTypes = _garrisonTypesForFaction(game, provinceOwnerId, defenderEffectiveLevel);
          for (var i = 0; i < recoverCount && defenderUnitIds.length < recoverCount; i++) {
            final type = garrisonTypes[i % garrisonTypes.length];
            final id = 'recover_${ctx.provinceId}_$i';
            defenderUnitIds.add(id);
            final stubUnit = Unit(
              id: id,
              type: type,
              ownerId: provinceOwnerId,
              provinceId: ctx.provinceId,
              medals: 0,
            );
            unitsById[id] = stubUnit;
          }
        }
        break;
    }
  }

  final survivingUnits = region.units
      .where((u) => !allCasualties.contains(u.id))
      .toList();

  var updatedProvinces = region.provinces;
  if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
    final idx = updatedProvinces.indexWhere((p) => p.id == ctx.provinceId);
    if (idx >= 0) {
      final p = updatedProvinces[idx];
      updatedProvinces = List<Province>.from(updatedProvinces)
        ..[idx] = p.copyWith(ownerId: survivingAttackerFactionId);
    }
  }

  final recoveredUnits = unitsById.values
      .where((u) => u.id.startsWith('recover_') && !allCasualties.contains(u.id))
      .toList();
  var finalUnits = [
    ...survivingUnits,
    ...recoveredUnits,
  ];

  // If the province changed hands during this battle, remove civilian units
  // in that province that do not belong to the new owner.
  if (provinceOwnerId != ctx.defenderFactionId) {
    final victorId = provinceOwnerId;
    finalUnits = finalUnits.where((u) {
      if (u.provinceId != ctx.provinceId) return true;
      // Military units remain; civilians of non-victor factions are removed.
      if (canUnitInitiateCombat(u.type)) return true;
      return u.ownerId == victorId;
    }).toList();
  }

  final newRegion = RegionData(
    provinces: updatedProvinces,
    units: finalUnits,
  );

  if (ctx.regionId == 'oldWorld') {
    return game.copyWith(
      worldState: game.worldState.copyWith(oldWorld: newRegion),
    );
  } else {
    return game.copyWith(
      worldState: game.worldState.copyWith(newWorld: newRegion),
    );
  }
}

void _sortAttackersByInitiative(
  List<AttackingSide> attackers,
  List<Unit> allUnits,
  Map<String, Unit> unitsById,
) {
  int cavalryCount(AttackingSide side) {
    var count = 0;
    for (final id in side.unitIds) {
      final u = unitsById[id];
      if (u == null) continue;
      final stats = regimentStatsById(u.type);
      if (stats != null && stats.isCavalry) count++;
    }
    return count;
  }

  attackers.sort((a, b) {
    final cavA = cavalryCount(a);
    final cavB = cavalryCount(b);
    final totalA = a.unitIds.length;
    final totalB = b.unitIds.length;
    final shareA = totalA > 0 ? cavA / totalA : 0.0;
    final shareB = totalB > 0 ? cavB / totalB : 0.0;
    final initA =
        shareA * initiativeCavalryShareWeight + a.generalMedals * initiativeGeneralMedalWeight;
    final initB =
        shareB * initiativeCavalryShareWeight + b.generalMedals * initiativeGeneralMedalWeight;
    final cmp = initB.compareTo(initA);
    if (cmp != 0) return cmp;
    return a.factionId.compareTo(b.factionId);
  });
}

int _defenderEffectiveLevel(Game game, String defenderFactionId) {
  for (final m in game.minorNations) {
    if (m.id == defenderFactionId) return m.effectiveMilitaryLevel;
  }
  for (final t in game.tribes) {
    if (t.id == defenderFactionId) return t.effectiveMilitaryLevel;
  }
  return 4;
}

List<String> _garrisonTypesForFaction(
  Game game,
  String factionId,
  int effectiveLevel,
) {
  final eraTypes = regimentCatalog
      .where((r) => r.era == effectiveLevel)
      .map((r) => r.id)
      .toList();
  if (eraTypes.isEmpty) return ['peasant_levies'];
  return eraTypes;
}

/// Resolves one engagement: attacker vs defender.
/// SPEC/program/combat-resolution.md.
EngagementOutcome resolveEngagement({
  required List<Unit> attackerUnits,
  required List<Unit> defenderUnits,
  int generalMedals = 0,
  required int fortLevel,
  required String terrain,
  int defenderEffectiveMilitaryLevel = 4,
  double attackerMoraleMultiplier = 1.0,
  double defenderMoraleMultiplier = 1.0,
}) {
  final attStr = _aggregateStrength(attackerUnits, 4);
  var defStr = _aggregateStrength(
    defenderUnits,
    defenderEffectiveMilitaryLevel,
  );

  final terrainMod = terrainModifiers[terrain] ?? (1.0, 1.0);
  var effAtt = attStr * terrainMod.$1 * attackerMoraleMultiplier;
  var effDef = defStr * terrainMod.$2 * defenderMoraleMultiplier;

  if (fortLevel >= 1 && fortLevel <= 3) {
    final reduction = fortDamageReduction[fortLevel];
    effAtt *= (1.0 - reduction);
    final emplaced = fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel];
    effDef += emplaced;
  }

  final attackerCasualties = <String>[];
  final defenderCasualties = <String>[];

  if (effAtt <= 0 && effDef <= 0) {
    return EngagementOutcome(
      result: EngagementResult.stalemate,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  final ratio = effDef > 0 ? effAtt / effDef : 10.0;
  final attackerLowMorale = attackerMoraleMultiplier < defenderMoraleMultiplier;

  if (ratio >= 1.5) {
    // If the attacker is underfed/low morale and the strength ratio is not
    // overwhelmingly in their favour, blunt the attack: do *not* award a
    // clean attacker victory. This ensures that reducing attacker morale
    // cannot lead to strictly better outcomes for the attacker than the
    // well‑fed case. SPEC/program: combat-resolution (morale as modifier).
    if (attackerLowMorale && ratio < 4.0) {
      final defLoss =
          (defenderUnits.length * 0.4).ceil().clamp(0, defenderUnits.length);
      for (var i = 0; i < defLoss && i < defenderUnits.length; i++) {
        defenderCasualties.add(defenderUnits[i].id);
      }
      final attLoss =
          (attackerUnits.length * 0.6).ceil().clamp(0, attackerUnits.length);
      for (var i = 0; i < attLoss && i < attackerUnits.length; i++) {
        attackerCasualties.add(attackerUnits[i].id);
      }
      final attSurvivors = attackerUnits.length - attLoss;
      final defSurvivors = defenderUnits.length - defLoss;

      final result = () {
        if (attSurvivors <= 0 && defSurvivors <= 0) {
          return EngagementResult.mutualAnnihilation;
        }
        if (attSurvivors <= 0) {
          return EngagementResult.defenderVictory;
        }
        if (defSurvivors <= 0) {
          // Underfed attacker cannot be granted a decisive victory here;
          // treat this as a bloody stalemate instead.
          return EngagementResult.stalemate;
        }
        return EngagementResult.stalemate;
      }();

      return EngagementOutcome(
        result: result,
        attackerCasualties: attackerCasualties,
        defenderCasualties: defenderCasualties,
        attackerStrength: attStr,
        defenderStrength: defStr,
      );
    }

    for (final u in defenderUnits) defenderCasualties.add(u.id);
    final attLoss =
        (attackerUnits.length * 0.15).ceil().clamp(0, attackerUnits.length);
    for (var i = 0; i < attLoss && i < attackerUnits.length; i++) {
      attackerCasualties.add(attackerUnits[i].id);
    }
    return EngagementOutcome(
      result: EngagementResult.attackerVictory,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  if (ratio <= 0.67) {
    for (final u in attackerUnits) attackerCasualties.add(u.id);
    final defLoss = (defenderUnits.length * 0.15).ceil().clamp(0, defenderUnits.length);
    for (var i = 0; i < defLoss && i < defenderUnits.length; i++) {
      defenderCasualties.add(defenderUnits[i].id);
    }
    return EngagementOutcome(
      result: EngagementResult.defenderVictory,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  if (ratio >= 1.0) {
    final defLoss = (defenderUnits.length * 0.6).ceil().clamp(0, defenderUnits.length);
    for (var i = 0; i < defLoss && i < defenderUnits.length; i++) {
      defenderCasualties.add(defenderUnits[i].id);
    }
    final attLoss = (attackerUnits.length * 0.3).ceil().clamp(0, attackerUnits.length);
    for (var i = 0; i < attLoss && i < attackerUnits.length; i++) {
      attackerCasualties.add(attackerUnits[i].id);
    }
    final attSurvivors = attackerUnits.length - attLoss;
    final defSurvivors = defenderUnits.length - defLoss;
    if (defSurvivors <= 0) {
      return EngagementOutcome(
        result: EngagementResult.attackerVictory,
        attackerCasualties: attackerCasualties,
        defenderCasualties: defenderCasualties,
        attackerStrength: attStr,
        defenderStrength: defStr,
      );
    }
    if (attSurvivors <= 0) {
      return EngagementOutcome(
        result: EngagementResult.defenderVictory,
        attackerCasualties: attackerCasualties,
        defenderCasualties: defenderCasualties,
        attackerStrength: attStr,
        defenderStrength: defStr,
      );
    }
    return EngagementOutcome(
      result: EngagementResult.stalemate,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  final defLoss = (defenderUnits.length * 0.4).ceil().clamp(0, defenderUnits.length);
  for (var i = 0; i < defLoss && i < defenderUnits.length; i++) {
    defenderCasualties.add(defenderUnits[i].id);
  }
  final attLoss = (attackerUnits.length * 0.5).ceil().clamp(0, attackerUnits.length);
  for (var i = 0; i < attLoss && i < attackerUnits.length; i++) {
    attackerCasualties.add(attackerUnits[i].id);
  }
  final attSurvivors = attackerUnits.length - attLoss;
  final defSurvivors = defenderUnits.length - defLoss;

  if (attSurvivors <= 0 && defSurvivors <= 0) {
    return EngagementOutcome(
      result: EngagementResult.mutualAnnihilation,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }
  if (attSurvivors <= 0) {
    return EngagementOutcome(
      result: EngagementResult.defenderVictory,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }
  if (defSurvivors <= 0) {
    return EngagementOutcome(
      result: EngagementResult.attackerVictory,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      attackerStrength: attStr,
      defenderStrength: defStr,
    );
  }

  return EngagementOutcome(
    result: EngagementResult.stalemate,
    attackerCasualties: attackerCasualties,
    defenderCasualties: defenderCasualties,
    attackerStrength: attStr,
    defenderStrength: defStr,
  );
}

double _aggregateStrength(List<Unit> units, int effectiveEra) {
  var total = 0.0;
  for (final u in units) {
    var stats = regimentStatsById(u.type);
    if (stats == null) continue;
    if (stats.era > effectiveEra) {
      stats = _downgradeToEra(stats, effectiveEra) ?? stats;
    }
    final mult = medalMultiplierFor(u.medals.clamp(0, 4));
    total += (stats.fpn + stats.fpm) * mult;
  }
  return total;
}

RegimentStats? _downgradeToEra(RegimentStats stats, int era) {
  final sameCategory = regimentCatalog
      .where((r) => r.category == stats.category && r.era == era)
      .toList();
  return sameCategory.isNotEmpty ? sameCategory.first : null;
}

double _moraleMultiplierForCoverage(double coverage) {
  if (coverage >= 1.0) return 1.0;
  if (coverage >= 0.5) return 0.75;
  return 0.5;
}

/// Aggregates military strength for a faction. SPEC/program/military-strength.md.
/// Uses the same formula as auto-resolve: sum of (FPN+FPM)*medalMultiplier per unit.
double aggregateMilitaryStrengthForPlayer(Game game, String playerId) {
  final owUnits = game.worldState.oldWorld.units.where((u) => u.ownerId == playerId).toList();
  final nwUnits = game.worldState.newWorld.units.where((u) => u.ownerId == playerId).toList();
  final effectiveEra = _defenderEffectiveLevel(game, playerId);
  return _aggregateStrength(owUnits, effectiveEra) + _aggregateStrength(nwUnits, effectiveEra);
}
