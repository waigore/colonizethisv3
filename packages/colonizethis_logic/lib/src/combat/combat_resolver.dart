import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/army_migration.dart';
import '../world/province_lookup.dart';
import '../world/province_ownership_transfer.dart';
import '../world/unit_lookup.dart';
import 'battle_general_assignment.dart';
import 'combat_constants.dart';
import 'combat_engagement.dart';
import 'combat_types.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';
import 'military_strength.dart';

export 'combat_constants.dart';
export 'combat_engagement.dart' show resolveEngagement;
export 'combat_types.dart';

/// Resolves one battle context and returns updated Game state.
/// SPEC/program/combat-resolution.md.
Game resolveBattleContext(
  Game game,
  BattleContext ctx, {
  Map<String, double> feedingCoverageByPlayerId = const {},
  CombatPhaseGeneralLedger? combatGeneralLedger,
}) {
  final ledger = combatGeneralLedger ?? CombatPhaseGeneralLedger();
  RegionData region;
  if (ctx.regionId == kRegionOldWorld) {
    region = game.worldState.oldWorld;
  } else {
    region = game.worldState.newWorld;
  }

  final unitsById = unitsByIdFromRegion(region);
  final provinceOwnerAtBattleStart =
      _provinceOwnerIdAtBattleStart(game, ctx) ?? ctx.defenderFactionId;
  var defenderUnitIds = ctx.defenderUnitIds.toList();
  var defenderFactionId = ctx.defenderFactionId;
  var provinceOwnerId = provinceOwnerAtBattleStart;
  var generalsById = {for (final g in game.generals) g.id: g};
  final battleRng = battleAssignmentRng(game, ctx);
  final attackerSidesWithMedals = ctx.attackers.map((att) {
    return _AttackingSideInBattle(side: att, assignedGeneralId: att.generalId);
  }).toList();
  _sortAttackersByInitiative(attackerSidesWithMedals, unitsById, battleRng);
  var currentDefenderGeneralId = ctx.defenderGeneralId;
  var currentDefenderMedals = ctx.defenderGeneralMedals;
  final defenderEffectiveLevelByFaction = <String, int>{};

  final allCasualties = <String>{};
  String? survivingAttackerFactionId;

  final initialDefenderCount = ctx.defenderUnitIds.length;

  for (
    var attackerIndex = 0;
    attackerIndex < attackerSidesWithMedals.length;
    attackerIndex++
  ) {
    final attacker = attackerSidesWithMedals[attackerIndex];
    if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
      break;
    }

    final attackerUnits = attacker.side.unitIds
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
      survivingAttackerFactionId = attacker.side.factionId;
      break;
    }

    // Deployment limit per side. SPEC/game/military-generals.md.
    final attackerLimit = _deploymentLimitForFaction(
      game,
      attacker.side.factionId,
      attacker.side.generalMedals,
    );
    final defenderLimit = _deploymentLimitForFaction(
      game,
      defenderFactionId,
      currentDefenderMedals,
    );
    final cappedAttackerUnits = attackerUnits.take(attackerLimit).toList();
    final cappedDefenderUnits = defenderUnits.take(defenderLimit).toList();

    final defenderEffectiveLevel = defenderEffectiveLevelByFaction.putIfAbsent(
      defenderFactionId,
      () => _defenderEffectiveLevel(game, defenderFactionId),
    );
    final attackerCoverage =
        feedingCoverageByPlayerId[attacker.side.factionId] ??
        kDefaultFeedingCoverageMultiplier;
    final defenderCoverage =
        feedingCoverageByPlayerId[defenderFactionId] ??
        kDefaultFeedingCoverageMultiplier;
    final attackerLeaderMult = leaderBonusForFaction(
      game,
      attacker.side.factionId,
    );
    final defenderLeaderMult = leaderBonusForFaction(game, defenderFactionId);
    final attackerGeneralMorale = moraleMultiplierForGeneralMedals(
      attacker.side.generalMedals,
    );
    final defenderGeneralMorale = moraleMultiplierForGeneralMedals(
      currentDefenderMedals,
    );
    final outcome = resolveEngagement(
      attackerUnits: cappedAttackerUnits,
      defenderUnits: cappedDefenderUnits,
      generalMedals: attacker.side.generalMedals,
      fortLevel: ctx.fortLevel,
      terrain: ctx.terrain,
      defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
      attackerMoraleMultiplier:
          moraleMultiplierForFeedingCoverage(attackerCoverage) *
          attackerGeneralMorale,
      defenderMoraleMultiplier:
          moraleMultiplierForFeedingCoverage(defenderCoverage) *
          defenderGeneralMorale,
      attackerLeaderMultiplier: attackerLeaderMult,
      defenderLeaderMultiplier: defenderLeaderMult,
    );
    logicLog.d(
      'combat engagement regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
      'attackerFactionId=${attacker.side.factionId} result=${outcome.result.name} '
      'attCasualties=${outcome.attackerCasualties.length} '
      'defCasualties=${outcome.defenderCasualties.length}',
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

    final updatedState = _applyEngagementOutcomeState(
      outcomeResult: outcome.result,
      attacker: attacker,
      currentDefenderGeneralId: currentDefenderGeneralId,
      currentDefenderMedals: currentDefenderMedals,
      provinceOwnerId: provinceOwnerId,
      defenderFactionId: defenderFactionId,
      survivingAttackerFactionId: survivingAttackerFactionId,
      defenderUnitIds: defenderUnitIds,
      attackerIndex: attackerIndex,
      attackerSidesWithMedals: attackerSidesWithMedals,
      initialDefenderCount: initialDefenderCount,
      defenderEffectiveLevel: defenderEffectiveLevel,
      generalsById: generalsById,
      unitsById: unitsById,
      ctx: ctx,
    );
    defenderFactionId = updatedState.defenderFactionId;
    provinceOwnerId = updatedState.provinceOwnerId;
    survivingAttackerFactionId = updatedState.survivingAttackerFactionId;
    currentDefenderGeneralId = updatedState.currentDefenderGeneralId;
    currentDefenderMedals = updatedState.currentDefenderMedals;
    defenderUnitIds = updatedState.defenderUnitIds;
  }

  final post = _buildPostBattleRegion(
    region: region,
    ctx: ctx,
    allCasualties: allCasualties,
    unitsById: unitsById,
    defenderFactionId: ctx.defenderFactionId,
    survivingAttackerFactionId: survivingAttackerFactionId,
    defenderUnitIds: defenderUnitIds,
  );

  final resolved = _buildResolvedBattleGame(
    game: game,
    ctx: ctx,
    post: post,
    survivingAttackerFactionId: survivingAttackerFactionId,
    generalsById: generalsById,
    ledger: ledger,
    provinceOwnerAtBattleStart: provinceOwnerAtBattleStart,
  );

  var ownerAfter = '';
  final row = resolveProvinceRowForOwnershipTransfer(
    resolved.worldState,
    ctx.provinceId,
  );
  if (row != null) {
    final regionState = ctx.regionId == kRegionOldWorld
        ? resolved.worldState.oldWorld
        : resolved.worldState.newWorld;
    for (final p in regionState.provinces) {
      if (p.id == row.canonicalProvinceId) {
        ownerAfter = p.ownerId ?? '';
        break;
      }
    }
  }
  logicLog.i(
    'combat battle_apply regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'mode=autoResolve provinceFlipped=${post.provinceChangedOwner} '
    'casualtiesApplied=${allCasualties.length} ownerAfter=$ownerAfter',
  );

  return resolved;
}

({
  String defenderFactionId,
  String provinceOwnerId,
  String? survivingAttackerFactionId,
  String? currentDefenderGeneralId,
  int currentDefenderMedals,
  List<String> defenderUnitIds,
})
_applyEngagementOutcomeState({
  required EngagementResult outcomeResult,
  required _AttackingSideInBattle attacker,
  required String? currentDefenderGeneralId,
  required int currentDefenderMedals,
  required String provinceOwnerId,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
  required int attackerIndex,
  required List<_AttackingSideInBattle> attackerSidesWithMedals,
  required int initialDefenderCount,
  required int defenderEffectiveLevel,
  required Map<String, General> generalsById,
  required Map<String, Unit> unitsById,
  required BattleContext ctx,
}) {
  switch (outcomeResult) {
    case EngagementResult.attackerVictory:
      _incrementGeneralMedals(
        generalsById: generalsById,
        generalId: attacker.assignedGeneralId,
      );
      final medalsAfterWin =
          attacker.side.generalMedals +
          (attacker.assignedGeneralId != null
              ? kGeneralMedalsGainedOnBattleWin
              : 0);
      return (
        defenderFactionId: attacker.side.factionId,
        provinceOwnerId: attacker.side.factionId,
        survivingAttackerFactionId: attacker.side.factionId,
        currentDefenderGeneralId: attacker.assignedGeneralId,
        currentDefenderMedals: medalsAfterWin > kGeneralMedalsMax
            ? kGeneralMedalsMax
            : medalsAfterWin,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.defenderVictory:
      _incrementGeneralMedals(
        generalsById: generalsById,
        generalId: currentDefenderGeneralId,
      );
      var updatedMedals = currentDefenderMedals;
      if (currentDefenderGeneralId != null) {
        final updatedGeneral = generalsById[currentDefenderGeneralId];
        if (updatedGeneral != null) {
          updatedMedals = updatedGeneral.medals;
        }
      }
      return (
        defenderFactionId: defenderFactionId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: null,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: updatedMedals,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.stalemate:
      return (
        defenderFactionId: defenderFactionId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: survivingAttackerFactionId,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: currentDefenderMedals,
        defenderUnitIds: defenderUnitIds,
      );
    case EngagementResult.mutualAnnihilation:
      final updatedDefenderIds = _recoverDefenderGarrisonIfNeeded(
        attackerIndex: attackerIndex,
        attackerSidesWithMedals: attackerSidesWithMedals,
        initialDefenderCount: initialDefenderCount,
        defenderEffectiveLevel: defenderEffectiveLevel,
        defenderUnitIds: defenderUnitIds,
        provinceOwnerId: provinceOwnerId,
        unitsById: unitsById,
        provinceId: ctx.provinceId,
      );
      return (
        defenderFactionId: provinceOwnerId,
        provinceOwnerId: provinceOwnerId,
        survivingAttackerFactionId: null,
        currentDefenderGeneralId: currentDefenderGeneralId,
        currentDefenderMedals: currentDefenderMedals,
        defenderUnitIds: updatedDefenderIds,
      );
  }
}

List<String> _recoverDefenderGarrisonIfNeeded({
  required int attackerIndex,
  required List<_AttackingSideInBattle> attackerSidesWithMedals,
  required int initialDefenderCount,
  required int defenderEffectiveLevel,
  required List<String> defenderUnitIds,
  required String provinceOwnerId,
  required Map<String, Unit> unitsById,
  required String provinceId,
}) {
  final remainingAttackers = attackerSidesWithMedals.skip(attackerIndex + 1);
  if (remainingAttackers.isEmpty) {
    return defenderUnitIds;
  }
  final recoverCount = (initialDefenderCount * kGarrisonRecoveryFraction)
      .ceil()
      .clamp(1, initialDefenderCount);
  final recoveryType = garrisonRecoveryRegimentTypeForEra(
    defenderEffectiveLevel,
  );
  final updatedDefenderIds = List<String>.from(defenderUnitIds);
  for (
    var i = 0;
    i < recoverCount && updatedDefenderIds.length < recoverCount;
    i++
  ) {
    final id = '${kRecoveryUnitPrefix}${provinceId}_$i';
    updatedDefenderIds.add(id);
    unitsById[id] = Unit(
      id: id,
      type: recoveryType,
      ownerId: provinceOwnerId,
      locationProvinceId: provinceId,
      medals: 0,
    );
  }
  return updatedDefenderIds;
}

String? _provinceOwnerIdAtBattleStart(Game game, BattleContext ctx) {
  final row = resolveProvinceRowForOwnershipTransfer(
    game.worldState,
    ctx.provinceId,
  );
  return row?.province.ownerId;
}

Game _buildResolvedBattleGame({
  required Game game,
  required BattleContext ctx,
  required ({RegionData region, bool provinceChangedOwner}) post,
  required String? survivingAttackerFactionId,
  required Map<String, General> generalsById,
  required CombatPhaseGeneralLedger ledger,
  required String provinceOwnerAtBattleStart,
}) {
  var newWorldState = game.worldState.updateRegionById(
    ctx.regionId,
    (_) => post.region,
  );

  recordAttackCommandersForResolvedBattle(ctx, null, ledger);

  var result = game.copyWith(
    worldState: newWorldState,
    generals: game.generals
        .map((g) => generalsById[g.id] ?? g)
        .toList(growable: false),
  );
  if (post.provinceChangedOwner && survivingAttackerFactionId != null) {
    result = applyCanonicalSingleProvinceOwnershipTransfer(
      result,
      targetProvinceId: ctx.provinceId,
      oldOwnerId: provinceOwnerAtBattleStart,
      newOwnerId: survivingAttackerFactionId,
    );
  } else {
    result = result.copyWith(
      worldState: reconcileArmiesAfterUnitsChanged(result.worldState, result),
    );
  }
  return result;
}

/// Builds post-battle region state: applies casualties, garrison recovery,
/// province ownership change, and civilian cleanup when province changes hands.
({RegionData region, bool provinceChangedOwner}) _buildPostBattleRegion({
  required RegionData region,
  required BattleContext ctx,
  required Set<String> allCasualties,
  required Map<String, Unit> unitsById,
  required String defenderFactionId,
  required String? survivingAttackerFactionId,
  required List<String> defenderUnitIds,
}) {
  final survivingUnits = region.units
      .where((u) => !allCasualties.contains(u.id))
      .toList();

  var updatedProvinces = region.provinces;
  var provinceChangedOwner = false;
  if (defenderUnitIds.isEmpty && survivingAttackerFactionId != null) {
    provinceChangedOwner = provinceListContainsProvinceId(
      updatedProvinces,
      ctx.provinceId,
    );
  }

  final recoveredUnits = unitsById.values
      .where(
        (u) =>
            u.id.startsWith(kRecoveryUnitPrefix) &&
            !allCasualties.contains(u.id),
      )
      .toList();
  var finalUnits = [...survivingUnits, ...recoveredUnits];

  final newRegion = RegionData(provinces: updatedProvinces, units: finalUnits);
  return (region: newRegion, provinceChangedOwner: provinceChangedOwner);
}

void _sortAttackersByInitiative(
  List<_AttackingSideInBattle> attackers,
  Map<String, Unit> unitsById,
  Random rng,
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

  final tieBreakRoll = rng.nextInt(kInitiativeTieBreakRngUpperExclusive);
  int tieRank(String factionId) => Object.hash(factionId, tieBreakRoll);
  final initiativeByAttacker = <_AttackingSideInBattle, double>{};
  for (final attacker in attackers) {
    final totalUnits = attacker.side.unitIds.length;
    final cavalryShare = totalUnits > 0
        ? cavalryCount(attacker.side) / totalUnits
        : kZeroCavalryShareWhenNoUnits;
    initiativeByAttacker[attacker] =
        cavalryShare * initiativeCavalryShareWeight +
        attacker.side.generalMedals * initiativeGeneralMedalWeight;
  }

  attackers.sort((a, b) {
    final initA = initiativeByAttacker[a]!;
    final initB = initiativeByAttacker[b]!;
    final cmp = initB.compareTo(initA);
    if (cmp != 0) return cmp;
    return tieRank(a.side.factionId).compareTo(tieRank(b.side.factionId));
  });
}

class _AttackingSideInBattle {
  const _AttackingSideInBattle({
    required this.side,
    required this.assignedGeneralId,
  });

  final AttackingSide side;
  final String? assignedGeneralId;
}

void _incrementGeneralMedals({
  required Map<String, General> generalsById,
  required String? generalId,
}) {
  if (generalId == null) return;
  final current = generalsById[generalId];
  if (current == null) return;
  generalsById[generalId] = current.copyWith(
    medals: (current.medals + kGeneralMedalsGainedOnBattleWin).clamp(
      kGeneralMedalsMin,
      kGeneralMedalsMax,
    ),
  );
}

int _defenderEffectiveLevel(Game game, String defenderFactionId) {
  for (final m in game.minorNations) {
    if (m.id == defenderFactionId) return m.effectiveMilitaryLevel;
  }
  for (final t in game.tribes) {
    if (t.id == defenderFactionId) return t.effectiveMilitaryLevel;
  }
  return kDefaultEffectiveMilitaryEra;
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

/// Morale aura from general medals. SPEC/game/military-generals.md:
/// 5% per general medal, up to 20% (at 4 medals).
double moraleMultiplierForGeneralMedals(int generalMedals) {
  final capped = generalMedals.clamp(kGeneralMedalsMin, kGeneralMedalsMax);
  return kMoraleMultiplierBaseFromGenerals +
      (capped * kMoraleMultiplierPerGeneralMedal);
}
