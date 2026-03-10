import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/fog_resolution.dart';
import '../world/unit_lookup.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';
import 'military_strength.dart';

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
  if (ctx.regionId == kRegionOldWorld) {
    region = game.worldState.oldWorld;
  } else {
    region = game.worldState.newWorld;
  }

  final unitsById = unitsByIdFromRegion(region);
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

    // Deployment limit per side. SPEC/game/military-generals.md.
    final attackerLimit = _deploymentLimitForFaction(
        game, attacker.factionId, attacker.generalMedals);
    final defenderLimit =
        _deploymentLimitForFaction(game, defenderFactionId, 0);
    final cappedAttackerUnits = attackerUnits.take(attackerLimit).toList();
    final cappedDefenderUnits = defenderUnits.take(defenderLimit).toList();

    final defenderEffectiveLevel =
        _defenderEffectiveLevel(game, defenderFactionId);
    final attackerCoverage =
        feedingCoverageByPlayerId[attacker.factionId] ?? 1.0;
    final defenderCoverage =
        feedingCoverageByPlayerId[defenderFactionId] ?? 1.0;
    final attackerLeaderMult = leaderBonusForFaction(game, attacker.factionId);
    final defenderLeaderMult = leaderBonusForFaction(game, defenderFactionId);
    final attackerGeneralMorale =
        moraleMultiplierForGeneralMedals(attacker.generalMedals);
    final defenderGeneralMorale = moraleMultiplierForGeneralMedals(0);
    final outcome = resolveEngagement(
      attackerUnits: cappedAttackerUnits,
      defenderUnits: cappedDefenderUnits,
      generalMedals: attacker.generalMedals,
      fortLevel: ctx.fortLevel,
      terrain: ctx.terrain,
      defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
      attackerMoraleMultiplier: _moraleMultiplierForCoverage(attackerCoverage) *
          attackerGeneralMorale,
      defenderMoraleMultiplier: _moraleMultiplierForCoverage(defenderCoverage) *
          defenderGeneralMorale,
      attackerLeaderMultiplier: attackerLeaderMult,
      defenderLeaderMultiplier: defenderLeaderMult,
    );

    for (final id in outcome.attackerCasualties) {
      allCasualties.add(id);
    }
    for (final id in outcome.defenderCasualties) {
      allCasualties.add(id);
    }

    // Casualties apply to full defender list; engagement was fought with capped subset.
    defenderUnitIds = defenderUnits
        .map((u) => u.id)
        .where((id) => !outcome.defenderCasualties.contains(id))
        .toList();

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
          final recoverCount = (initialDefenderCount * 0.2)
              .ceil()
              .clamp(1, initialDefenderCount);
          final garrisonTypes = _garrisonTypesForFaction(
              game, provinceOwnerId, defenderEffectiveLevel);
          for (var i = 0;
              i < recoverCount && defenderUnitIds.length < recoverCount;
              i++) {
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

  final post = _buildPostBattleRegion(
    region: region,
    ctx: ctx,
    allCasualties: allCasualties,
    unitsById: unitsById,
    provinceOwnerId: provinceOwnerId,
    defenderFactionId: ctx.defenderFactionId,
    survivingAttackerFactionId: survivingAttackerFactionId,
    defenderUnitIds: defenderUnitIds,
  );

  var newWorldState = ctx.regionId == kRegionOldWorld
      ? game.worldState.copyWith(oldWorld: post.region)
      : game.worldState.copyWith(newWorld: post.region);

  if (post.provinceChangedOwner && survivingAttackerFactionId != null) {
    final timers = clearSpyRevealTimersForProvince(
      game.worldState.spyRevealTurnsByPlayer,
      survivingAttackerFactionId,
      ctx.provinceId,
    );
    newWorldState = newWorldState.copyWith(spyRevealTurnsByPlayer: timers);
  }

  return game.copyWith(worldState: newWorldState);
}

/// Builds post-battle region state: applies casualties, garrison recovery,
/// province ownership change, and civilian cleanup when province changes hands.
({RegionData region, bool provinceChangedOwner}) _buildPostBattleRegion({
  required RegionData region,
  required BattleContext ctx,
  required List<String> allCasualties,
  required Map<String, Unit> unitsById,
  required String provinceOwnerId,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
}) {
  final survivingUnits =
      region.units.where((u) => !allCasualties.contains(u.id)).toList();

  var updatedProvinces = region.provinces;
  var ownerId = provinceOwnerId;
  var provinceChangedOwner = false;
  if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
    final idx = updatedProvinces.indexWhere((p) => p.id == ctx.provinceId);
    if (idx >= 0) {
      final p = updatedProvinces[idx];
      updatedProvinces = List<Province>.from(updatedProvinces)
        ..[idx] = p.copyWith(ownerId: survivingAttackerFactionId);
      ownerId = survivingAttackerFactionId;
      provinceChangedOwner = true;
    }
  }

  final recoveredUnits = unitsById.values
      .where(
        (u) => u.id.startsWith('recover_') && !allCasualties.contains(u.id),
      )
      .toList();
  var finalUnits = [
    ...survivingUnits,
    ...recoveredUnits,
  ];

  // If the province changed hands during this battle, remove civilian units
  // in that province that do not belong to the new owner.
  if (ownerId != defenderFactionId) {
    final victorId = ownerId;
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
  return (region: newRegion, provinceChangedOwner: provinceChangedOwner);
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
    final initA = shareA * initiativeCavalryShareWeight +
        a.generalMedals * initiativeGeneralMedalWeight;
    final initB = shareB * initiativeCavalryShareWeight +
        b.generalMedals * initiativeGeneralMedalWeight;
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

/// Max regiments that can participate per side in one engagement.
/// SPEC/game/military-generals.md: base 10; Nationalism tech → 12; +1 per general medal.
int _deploymentLimitForFaction(Game game, String factionId, int generalMedals) {
  final baseLimit =
      game.playerById(factionId)?.techUnlocked?[kTechIdNationalism] == true
          ? deploymentLimitWithNationalism
          : deploymentLimitBase;
  return baseLimit + generalMedals;
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
  double attackerLeaderMultiplier = 1.0,
  double defenderLeaderMultiplier = 1.0,
}) {
  final attStr = aggregateStrength(attackerUnits, 4);
  var defStr = aggregateStrength(
    defenderUnits,
    defenderEffectiveMilitaryLevel,
  );

  final terrainMod = terrainModifiers[terrain] ?? (1.0, 1.0);
  var effAtt = attStr *
      terrainMod.$1 *
      attackerMoraleMultiplier *
      attackerLeaderMultiplier;
  var effDef = defStr *
      terrainMod.$2 *
      defenderMoraleMultiplier *
      defenderLeaderMultiplier;

  if (fortLevel >= 1 && fortLevel <= 3) {
    final reduction = fortDamageReduction[fortLevel];
    effAtt *= (1.0 - reduction);
    final emplaced = fortGunCount[fortLevel] * fortEmplacedStrength[fortLevel];
    effDef += emplaced;
  }

  // Wall HP soaks damage before it applies to defender casualty ratio. SPEC/game/siege-mechanics.md.
  var effAttForRatio = effAtt;
  if (fortLevel >= 1 && fortLevel <= 3) {
    final wallHp = wallHpByFortLevel[fortLevel];
    effAttForRatio = (effAtt - wallHp).clamp(0.0, double.infinity);
  }

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

  final ratio = effDef > 0 ? effAttForRatio / effDef : 10.0;
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
  double attLossFrac;
  double defLossFrac;
  bool bluntAttackerVictory = false;

  EngagementResult bothDeadResult = EngagementResult.mutualAnnihilation;

  if (ratio >= 1.5 && attackerLowMorale && ratio < 4.0) {
    attLossFrac = 0.6;
    defLossFrac = 0.4;
    bluntAttackerVictory = true;
  } else if (ratio >= 1.5) {
    attLossFrac = 0.15;
    defLossFrac = 1.0;
    bothDeadResult = EngagementResult.attackerVictory;
  } else if (ratio <= 0.67) {
    attLossFrac = 1.0;
    defLossFrac = 0.15;
    bothDeadResult = EngagementResult.defenderVictory;
  } else if (ratio >= 1.0) {
    attLossFrac = 0.3;
    defLossFrac = 0.6;
    bothDeadResult = EngagementResult.attackerVictory;
  } else {
    attLossFrac = 0.5;
    defLossFrac = 0.4;
  }

  return _buildOutcome(
    attackerUnits: attackerUnits,
    defenderUnits: defenderUnits,
    attLossFrac: attLossFrac,
    defLossFrac: defLossFrac,
    attStr: attStr,
    defStr: defStr,
    bluntAttackerVictory: bluntAttackerVictory,
    bothDeadResult: bothDeadResult,
  );
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
  final attLoss = (attackerUnits.length * attLossFrac)
      .ceil()
      .clamp(0, attackerUnits.length);
  final defLoss = (defenderUnits.length * defLossFrac)
      .ceil()
      .clamp(0, defenderUnits.length);

  final attackerCasualties = [
    for (var i = 0; i < attLoss; i++) attackerUnits[i].id
  ];
  final defenderCasualties = [
    for (var i = 0; i < defLoss; i++) defenderUnits[i].id
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

double _moraleMultiplierForCoverage(double coverage) {
  if (coverage >= 1.0) return 1.0;
  if (coverage >= 0.5) return 0.75;
  return 0.5;
}

/// Morale aura from general medals. SPEC/game/military-generals.md:
/// 5% per general medal, up to 20% (at 4 medals).
double moraleMultiplierForGeneralMedals(int generalMedals) {
  final capped = generalMedals.clamp(0, 4);
  return 1.0 + (capped * 0.05);
}
