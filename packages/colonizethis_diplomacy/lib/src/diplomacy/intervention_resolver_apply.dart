import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_combat/src/combat/conflict_detection.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_relation_updates.dart';
import 'overture_resolver.dart';

/// True when [gpId] has purchased land tiles inside provinces owned by
/// [factionId]. Package-visible so the intervention resolver library can reuse
/// the same investment check (Refs #3419).
bool gpHasPurchasedLandInFactionProvinces(
  Game game,
  String gpId,
  String factionId,
) {
  if (game.worldState.purchasedTilesByTileKey.isEmpty) return false;
  final worldState = game.worldState;
  for (final entry in worldState.purchasedTilesByTileKey.entries) {
    if (entry.value != gpId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = worldState.tryGetProvince(provinceId);
    if (province != null && province.ownerId == factionId) {
      return true;
    }
  }
  return false;
}

Game _clearOverturesBetweenGpAndMinorTribe(
  Game game,
  String gpId,
  String minorOrTribeId,
) {
  final overtures = game.overtureStates
      .where((o) => !(o.gpId == gpId && o.targetId == minorOrTribeId))
      .toList();
  if (overtures.length == game.overtureStates.length) return game;
  return game.copyWith(overtureStates: overtures);
}

/// Applies intervention for one aggressor GP (Diplomacy phase when a GP declares
/// war on a Minor/Tribe; legacy combat hook may use [applyInterventionChoice]).
/// SPEC/game/diplomacy.md § Intervention.
Game applyInterventionAgainstAggressor(
  Game game, {
  required String aggressorGpId,
  required String defenderMinorOrTribeId,
  required String interveningGpId,
  required InterventionChoice choice,
  DiplomacyFactionMembership? factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  final turn = game.worldState.turnState.turnNumber;
  final aggressorIsGp =
      factionMembership?.isGreatPower(aggressorGpId) ??
      isGreatPower(game, aggressorGpId);
  if (!aggressorIsGp) return game;

  if (choice == InterventionChoice.doNothing) {
    var g = _clearOverturesBetweenGpAndMinorTribe(
      game,
      interveningGpId,
      defenderMinorOrTribeId,
    );
    g = appendDiplomaticEvent(
      g,
      turn,
      DiplomaticEventType.interventionDoNothing,
      {interveningGpId, aggressorGpId},
      fromFactionId: interveningGpId,
      toFactionId: aggressorGpId,
      eventTally: eventTally,
    );
    return g;
  }

  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);

  if (choice == InterventionChoice.intervene) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      if (existing == null) {
        return DiplomacyRelation(
          factionId1: ids.id1,
          factionId2: ids.id2,
          score: 40,
          level: RelationLevel.neutral,
          state: RelationState.atWar,
          sinceTurn: turn,
          lastInteractionTurn: turn,
        );
      }
      if (!existing.atPeace) return existing;
      final delta = warDeclarationThirdPartyPenaltyDelta(game, aggressorGpId);
      final newScore = (existing.score - delta).clamp(
        relationScoreMin,
        relationScoreMax,
      );
      return existing.copyWith(
        state: RelationState.atWar,
        sinceTurn: turn,
        lastInteractionTurn: turn,
        score: newScore,
        level: scoreToLevel(newScore),
      );
    });
  } else if (choice == InterventionChoice.protest) {
    final ids = canonicalPairIds(interveningGpId, aggressorGpId);
    relations = upsertRelation(relations, interveningGpId, aggressorGpId, (
      existing,
    ) {
      final delta = warDeclarationThirdPartyPenaltyDelta(game, aggressorGpId);
      final newScore = ((existing?.score ?? relationScoreNeutral) - delta)
          .clamp(relationScoreMin, relationScoreMax);
      final newLevel = scoreToLevel(newScore);
      if (existing == null) {
        return DiplomacyRelation(
          factionId1: ids.id1,
          factionId2: ids.id2,
          score: newScore,
          level: newLevel,
          lastInteractionTurn: turn,
        );
      }
      return existing.copyWith(
        score: newScore,
        level: newLevel,
        lastInteractionTurn: turn,
      );
    });
  }

  var g = game.copyWith(diplomacyRelations: relations);
  final eventType = choice == InterventionChoice.intervene
      ? DiplomaticEventType.interventionIntervene
      : DiplomaticEventType.interventionProtest;
  g = appendDiplomaticEvent(
    g,
    turn,
    eventType,
    {interveningGpId, aggressorGpId},
    fromFactionId: interveningGpId,
    toFactionId: aggressorGpId,
    eventTally: eventTally,
  );
  return g;
}

/// Returns gpId of a human GP with Embassy or purchased land for the
/// Minor/Tribe defender, or null. Used for tests and legacy combat hooks;
/// primary intervention flow runs in the Diplomacy phase.
String? needsInterventionChoice(Game game, BattleContext ctx) {
  final effectiveMembership = DiplomacyFactionMembership.from(game);
  final defenderId = ctx.defenderFactionId;
  final defenderIsMinorOrTribe = effectiveMembership.isMinorOrTribe(defenderId);
  if (!defenderIsMinorOrTribe) return null;

  final attackerIds = ctx.attackers.map((a) => a.factionId).toSet();
  final attackerIsGp = attackerIds.any(effectiveMembership.isGreatPower);
  if (!attackerIsGp) return null;

  for (final p in game.players) {
    if (!p.isHuman) continue;
    if (attackerIds.contains(p.id)) continue;

    final o = getOverture(game, p.id, defenderId);
    final hasEmbassy = o != null && o.hasEmbassy;
    final hasInvestment = gpHasPurchasedLandInFactionProvinces(
      game,
      p.id,
      defenderId,
    );
    if (hasEmbassy || hasInvestment) return p.id;
  }
  return null;
}

/// Applies intervention for each Great Power attacker in [ctx] (legacy combat hook).
/// Prefer [applyInterventionAgainstAggressor] for Diplomacy-phase declaration flow.
Game applyInterventionChoice(
  Game game,
  BattleContext ctx,
  String gpIdWithEmbassy,
  InterventionChoice choice,
) {
  final effectiveMembership = DiplomacyFactionMembership.from(game);
  var g = game;
  for (final a in ctx.attackers) {
    final attackerId = a.factionId;
    if (!effectiveMembership.isGreatPower(attackerId)) continue;
    g = applyInterventionAgainstAggressor(
      g,
      aggressorGpId: attackerId,
      defenderMinorOrTribeId: ctx.defenderFactionId,
      interveningGpId: gpIdWithEmbassy,
      choice: choice,
      factionMembership: effectiveMembership,
    );
  }
  return g;
}
