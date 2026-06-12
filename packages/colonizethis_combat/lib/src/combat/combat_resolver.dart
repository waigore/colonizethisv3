import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
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

part 'combat_resolver_engagement_outcome.dart';
part 'combat_resolver_post_battle.dart';
part 'combat_resolver_support.dart';

/// Resolves one battle context and returns updated Game state.
/// SPEC/program/combat-resolution.md.
Game resolveBattleContext(
  Game game,
  BattleContext ctx, {
  Map<String, double> feedingCoverageByPlayerId = const {},
  CombatPhaseGeneralLedger? combatGeneralLedger,
}) {
  final ledger = combatGeneralLedger ?? CombatPhaseGeneralLedger();
  final region = game.worldState.regionDataForIdOrThrow(ctx.regionId);

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
      () => effectiveEraForFaction(game, defenderFactionId),
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
    combatLog.d(
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
    final regionState = resolved.worldState.regionDataForIdOrThrow(
      ctx.regionId,
    );
    for (final p in regionState.provinces) {
      if (p.id == row.canonicalProvinceId) {
        ownerAfter = p.ownerId ?? '';
        break;
      }
    }
  }
  combatLog.i(
    'combat battle_apply regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'mode=autoResolve provinceFlipped=${post.provinceChangedOwner} '
    'casualtiesApplied=${allCasualties.length} ownerAfter=$ownerAfter',
  );

  return resolved;
}
