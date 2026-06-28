import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'diplomacy_shared_helpers.dart';
import 'faction_absorption_engine.dart';
import 'overture_resolver.dart';

Game resolveJoinEmpireColony(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  var factionMembership = DiplomacyFactionMembership.from(game);
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      final prev = game;
      game = _resolveJoinEmpireOrderIfApplicable(
        game,
        gpId,
        order,
        turn,
        factionMembership,
        eventTally: eventTally,
      );
      if (!identical(game, prev)) {
        factionMembership = DiplomacyFactionMembership.from(game);
      }
    }
  }
  return game;
}

Game _resolveJoinEmpireOrderIfApplicable(
  Game game,
  String gpId,
  DiplomaticOrder order,
  int turn,
  DiplomacyFactionMembership factionMembership, {
  IntraTurnEventTally? eventTally,
}) {
  if (order.type != DiplomaticOrderType.establishOverture) return game;
  if (order.overtureStage != OvertureStage.joinEmpire) return game;

  final targetId = order.targetFactionId;
  final player = game.playerById(gpId);
  if (player == null) return game;

  final existing = getOverture(game, gpId, targetId);
  if (existing == null || existing.stage != OvertureStage.nap) return game;

  final rel = getRelation(game, gpId, targetId);
  final score = rel?.score ?? relationScoreNeutral;
  if (score < relationScoreMinFriendly) return game;

  if (factionMembership.isMinorOrTribe(targetId)) {
    return _resolveJoinEmpireMinorOrTribe(
      game,
      gpId,
      targetId,
      player,
      turn,
      eventTally: eventTally,
    );
  }
  if (factionMembership.isGreatPower(targetId)) {
    return _resolveJoinEmpireGreatPower(
      game,
      gpId,
      targetId,
      player,
      turn,
      factionMembership,
      eventTally: eventTally,
    );
  }
  return game;
}

Game _resolveJoinEmpireMinorOrTribe(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn, {
  IntraTurnEventTally? eventTally,
}) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;

  // Tribes become colonies (stay in the game); Minors are absorbed.
  // SPEC/game/diplomacy.md § GP–Minor/Tribe Rules (Join Empire → colony).
  final isTribe = game.tribes.any((t) => t.id == targetId);
  var next = isTribe
      ? markTribeAsColony(game, gpId, targetId, turn)
      : absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
  next = logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
    eventTally: eventTally,
    logMessage: isTribe
        ? 'diplomacy join empire (colony) $gpId $targetId cost=$cost'
        : 'diplomacy join empire $gpId $targetId cost=$cost',
  );
  return next;
}

Game _resolveJoinEmpireGreatPower(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn,
  DiplomacyFactionMembership factionMembership, {
  IntraTurnEventTally? eventTally,
}) {
  if (player.techUnlocked?[kTechIdEmpireBuilding] != true) return game;
  if (!isGreatPowerNearlyDefeatedForJoinEmpire(
    game,
    targetId,
    factionMembership: factionMembership,
  )) {
    return game;
  }

  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;

  var next = absorbGreatPowerIntoGp(game, gpId, targetId);
  next = logDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
    eventTally: eventTally,
    logMessage: 'diplomacy join empire GP $gpId absorbs $targetId cost=$cost',
  );
  return next;
}

/// Transfers all provinces, units, and fleets owned by [targetId] to [gpId],
/// deducts Join Empire cost from GP treasury, removes the Minor/Tribe and
/// cleans overtures/relations. SPEC/game/diplomacy.md.
Game absorbMinorOrTribeIntoGp(
  Game game,
  String gpId,
  String targetId,
  int turn,
) => FactionAbsorptionEngine.absorbMinorOrTribeIntoGp(
  game,
  gpId,
  targetId,
  turn,
);

Game absorbGreatPowerIntoGp(Game game, String gpId, String targetGpId) =>
    FactionAbsorptionEngine.absorbGreatPowerIntoGp(game, gpId, targetGpId);

/// Marks Tribe [tribeId] as a colony of [gpId] (Tribe Join Empire outcome):
/// deducts the Join Empire cost, records a [ColonyState], and keeps the Tribe
/// in the game (no province/unit/fleet transfer). SPEC/game/diplomacy.md.
Game markTribeAsColony(Game game, String gpId, String tribeId, int turn) =>
    FactionAbsorptionEngine.markTribeAsColony(game, gpId, tribeId, turn);

Game processAlliances(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  IntraTurnEventTally? eventTally,
}) {
  // Single per-phase relation index so each accepted alliance upsert is
  // amortized O(1) instead of rebuilding the pair-key index per order
  // (Refs #3562 AC5).
  final relationsIndex = RelationUpsertIndex(game.diplomacyRelations);
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.alliance) continue;

      final targetId = order.targetFactionId;
      if (!factionMembership.isGreatPower(targetId)) continue;

      final ids = canonicalPairIds(gpId, targetId);
      relationsIndex.upsert(
        gpId,
        targetId,
        (existing) => existing == null
            ? DiplomacyRelation(
                factionId1: ids.id1,
                factionId2: ids.id2,
                score: relationScoreMinAllied,
                level: RelationLevel.allied,
                state: RelationState.atPeace,
                sinceTurn: turn,
                lastInteractionTurn: turn,
                formalAlliance: true,
              )
            : existing.copyWith(
                level: RelationLevel.allied,
                score: existing.score.clamp(
                  relationScoreMinAllied,
                  relationScoreMax,
                ),
                lastInteractionTurn: turn,
                formalAlliance: true,
              ),
      );
      game = game.copyWith(diplomacyRelations: relationsIndex.toList());
      game = logDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.allianceFormed,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
        eventTally: eventTally,
        logMessage: 'diplomacy alliance $gpId-$targetId',
      );
    }
  }
  return game;
}
