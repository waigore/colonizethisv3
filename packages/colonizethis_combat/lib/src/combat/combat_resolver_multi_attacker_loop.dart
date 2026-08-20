import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_constants.dart';
import 'combat_engagement.dart';
import 'combat_resolver_engagement_outcome.dart';
import 'combat_resolver_support.dart';
import 'combat_rng.dart';
import 'combat_survivor_units.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';
import 'military_strength.dart';

/// Result of the multi-attacker engagement loop inside [resolveBattleContext].
({
  Set<String> allCasualties,
  int attackerCasualtyCount,
  int defenderCasualtyCount,
  String? survivingAttackerFactionId,
  List<String> defenderUnitIds,
  Map<String, General> generalsById,
})
runLandBattleMultiAttackerLoop({
  required Game game,
  required BattleContext ctx,
  required Map<String, Unit> unitsById,
  required String provinceOwnerAtBattleStart,
  required Map<String, double> feedingCoverageByPlayerId,
}) {
  // Keep (copy-disposition, Refs #3448 AC5): mutation-isolated working copy of
  // the defender unit ids; this engagement reassigns it as the defender changes.
  var defenderUnitIds = ctx.defenderUnitIds.toList();
  var defenderFactionId = ctx.defenderFactionId;
  var provinceOwnerId = provinceOwnerAtBattleStart;
  var generalsById = {for (final g in game.generals) g.id: g};
  final battleRng = battleAssignmentRng(game, ctx);
  final attackerSidesWithMedals = ctx.attackers.map((att) {
    return AttackingSideInBattle(side: att, assignedGeneralId: att.generalId);
  }).toList();
  sortAttackersByInitiative(attackerSidesWithMedals, unitsById, battleRng);
  var currentDefenderGeneralId = ctx.defenderGeneralId;
  var currentDefenderMedals = ctx.defenderGeneralMedals;
  final defenderEffectiveLevelByFaction = <String, int>{};

  final allCasualties = <String>{};
  var attackerCasualtyCount = 0;
  var defenderCasualtyCount = 0;
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

    final attackerUnits = unitsExcludingCasualtyIds(
      attacker.side.unitIds.map((id) => unitsById[id]).whereType<Unit>(),
      allCasualties,
    ).toList();

    if (attackerUnits.isEmpty) continue;

    final defenderUnits = unitsExcludingCasualtyIds(
      defenderUnitIds.map((id) => unitsById[id]).whereType<Unit>(),
      allCasualties,
    ).toList();

    if (defenderUnits.isEmpty) {
      survivingAttackerFactionId = attacker.side.factionId;
      break;
    }

    // Deployment limit per side. SPEC/game/military-generals.md.
    final attackerLimit = deploymentLimitForFaction(
      game,
      attacker.side.factionId,
      attacker.side.generalMedals,
    );
    final defenderLimit = deploymentLimitForFaction(
      game,
      defenderFactionId,
      currentDefenderMedals,
    );
    // Keep (copy-disposition, Refs #3448 AC5): per-engagement capping
    // materialization (take(...).toList()), not a defensive ship/unit clone.
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
    final outcome = resolveEngagement(
      attackerUnits: cappedAttackerUnits,
      defenderUnits: cappedDefenderUnits,
      generalMedals: attacker.side.generalMedals,
      fortLevel: ctx.fortLevel,
      terrain: ctx.terrain,
      defenderEffectiveMilitaryLevel: defenderEffectiveLevel,
      attackerMoraleMultiplier: combatSideMoraleMultiplier(
        feedingCoverage: attackerCoverage,
        generalMedals: attacker.side.generalMedals,
      ),
      defenderMoraleMultiplier: combatSideMoraleMultiplier(
        feedingCoverage: defenderCoverage,
        generalMedals: currentDefenderMedals,
      ),
      attackerLeaderMultiplier: attackerLeaderMult,
      defenderLeaderMultiplier: defenderLeaderMult,
    );
    combatLog.d(
      'combat engagement regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
      'attackerFactionId=${attacker.side.factionId} result=${outcome.result.name} '
      'attCasualties=${outcome.attackerCasualties.length} '
      'defCasualties=${outcome.defenderCasualties.length}',
    );

    attackerCasualtyCount += outcome.attackerCasualties.length;
    defenderCasualtyCount += outcome.defenderCasualties.length;
    for (final id in outcome.attackerCasualties) {
      allCasualties.add(id);
    }
    for (final id in outcome.defenderCasualties) {
      allCasualties.add(id);
    }

    // Casualties apply to full defender list; engagement was fought with capped subset.
    defenderUnitIds = idsExcludingCasualtyIds(
      defenderUnits.map((u) => u.id),
      outcome.defenderCasualties.toSet(),
    ).toList();

    final updatedState = applyEngagementOutcomeState(
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

  return (
    allCasualties: allCasualties,
    attackerCasualtyCount: attackerCasualtyCount,
    defenderCasualtyCount: defenderCasualtyCount,
    survivingAttackerFactionId: survivingAttackerFactionId,
    defenderUnitIds: defenderUnitIds,
    generalsById: generalsById,
  );
}
