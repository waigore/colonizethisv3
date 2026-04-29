import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../dossier/evidence_rules.dart';
import '../world/army_migration.dart';
import '../world/civilian_ownership_legality.dart';
import '../world/province_ownership_transfer.dart';
import 'diplomacy_relation_updates.dart';
import 'diplomacy_resolver.dart';
import 'overture_resolver.dart';

Game resolveJoinEmpireColony(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      game = _resolveJoinEmpireOrderIfApplicable(game, gpId, order, turn);
    }
  }
  return game;
}

Game _resolveJoinEmpireOrderIfApplicable(
  Game game,
  String gpId,
  DiplomaticOrder order,
  int turn,
) {
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

  if (isMinorOrTribe(game, targetId)) {
    return _resolveJoinEmpireMinorOrTribe(game, gpId, targetId, player, turn);
  }
  if (isGreatPower(game, targetId)) {
    return _resolveJoinEmpireGreatPower(game, gpId, targetId, player, turn);
  }
  return game;
}

Game _resolveJoinEmpireMinorOrTribe(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn,
) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;

  var next = absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
  next = appendDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
  );
  diploLog.i('diplomacy join empire $gpId $targetId cost=$cost');
  return next;
}

Game _resolveJoinEmpireGreatPower(
  Game game,
  String gpId,
  String targetId,
  Player player,
  int turn,
) {
  if (player.techUnlocked?[kTechIdEmpireBuilding] != true) return game;
  if (!isGreatPowerNearlyDefeatedForJoinEmpire(game, targetId)) return game;

  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  if (player.treasury < cost) return game;

  var next = absorbGreatPowerIntoGp(game, gpId, targetId);
  next = appendDiplomaticEvent(
    next,
    turn,
    DiplomaticEventType.joinEmpireResolved,
    {gpId, targetId},
    fromFactionId: gpId,
    toFactionId: targetId,
    overtureStage: OvertureStage.joinEmpire,
    amount: cost,
    wasAiInitiator: isAiControlledForEvidence(next, gpId),
  );
  diploLog.i('diplomacy join empire GP $gpId absorbs $targetId cost=$cost');
  return next;
}

List<String> _sortedFullProvinceIdsOwnedBy(
  Game game,
  String ownerId,
) {
  final ids = <String>[];
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId == ownerId) ids.add(p.id);
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId == ownerId) ids.add(p.id);
  }
  ids.sort();
  return ids;
}

List<Fleet> _remapAllFleetsFromTo(
  List<Fleet> fleets,
  String fromId,
  String toId,
) {
  return fleets
      .map(
        (f) => f.ownerId == fromId ? f.copyWith(ownerId: toId) : f,
      )
      .toList();
}

List<Unit> _remapAllUnitsFromTo(List<Unit> units, String fromId, String toId) {
  return units
      .map((u) => u.ownerId == fromId ? u.copyWith(ownerId: toId) : u)
      .toList();
}

Map<String, Map<String, int>> _spyTimersWithoutPlayer(
  Map<String, Map<String, int>> existing,
  String playerId,
) {
  final next = <String, Map<String, int>>{};
  existing.forEach((pid, byProv) {
    if (pid == playerId) return;
    if (byProv.isNotEmpty) {
      next[pid] = Map<String, int>.from(byProv);
    }
  });
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
) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetId);
  var players = List<Player>.from(game.players);
  final gpIdx = players.indexWhere((p) => p.id == gpId);
  if (gpIdx >= 0) {
    players = List<Player>.from(players);
    players[gpIdx] = players[gpIdx].copyWith(
      treasury: players[gpIdx].treasury - cost,
    );
  }

  final provinceIds = _sortedFullProvinceIdsOwnedBy(game, targetId);
  var next = game.copyWith(players: players);
  final bulk = applyBulkCanonicalProvinceOwnershipTransfers(
    next,
    provinceIdsInOrder: provinceIds,
    oldOwnerId: targetId,
    newOwnerId: gpId,
    relocateIllegalCivilians: false,
  );
  next = bulk.game;

  next = next.copyWith(
    worldState: next.worldState.copyWith(
      fleets: _remapAllFleetsFromTo(
        next.worldState.fleets,
        targetId,
        gpId,
      ),
      oldWorld: RegionData(
        provinces: next.worldState.oldWorld.provinces,
        units: _remapAllUnitsFromTo(
          next.worldState.oldWorld.units,
          targetId,
          gpId,
        ),
      ),
      newWorld: RegionData(
        provinces: next.worldState.newWorld.provinces,
        units: _remapAllUnitsFromTo(
          next.worldState.newWorld.units,
          targetId,
          gpId,
        ),
      ),
      spyRevealTurnsByPlayer: _spyTimersWithoutPlayer(
        next.worldState.spyRevealTurnsByPlayer,
        targetId,
      ),
    ),
  );

  next = relocateIllegalCiviliansInChangedProvinces(
    next,
    changedProvinceIds: Set<String>.from(provinceIds),
  );

  next = next.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(
      next.worldState,
      next,
    ),
  );

  var minorNations = next.minorNations;
  var tribes = next.tribes;
  if (next.minorNations.any((m) => m.id == targetId)) {
    minorNations = next.minorNations.where((m) => m.id != targetId).toList();
  }
  if (next.tribes.any((t) => t.id == targetId)) {
    tribes = next.tribes.where((t) => t.id != targetId).toList();
  }

  final overtures = next.overtureStates
      .where((o) => o.targetId != targetId)
      .toList();

  final relations = next.diplomacyRelations
      .where((r) => r.factionId1 != targetId && r.factionId2 != targetId)
      .toList();

  return next.copyWith(
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtures,
    diplomacyRelations: relations,
  );
}

Game absorbGreatPowerIntoGp(Game game, String gpId, String targetGpId) {
  final cost = joinEmpireCostForMinorOrTribe(game, targetGpId);
  var players = List<Player>.from(game.players);
  final gpIdx = players.indexWhere((p) => p.id == gpId);
  final targetIdx = players.indexWhere((p) => p.id == targetGpId);
  if (gpIdx < 0 || targetIdx < 0) return game;

  players[gpIdx] = players[gpIdx].copyWith(
    treasury: players[gpIdx].treasury - cost,
  );
  players.removeAt(targetIdx);

  final provinceIds = _sortedFullProvinceIdsOwnedBy(game, targetGpId);
  var next = game.copyWith(players: players);
  final bulk = applyBulkCanonicalProvinceOwnershipTransfers(
    next,
    provinceIdsInOrder: provinceIds,
    oldOwnerId: targetGpId,
    newOwnerId: gpId,
    relocateIllegalCivilians: false,
  );
  next = bulk.game;

  final generals = next.generals
      .map((g) => g.ownerId == targetGpId ? g.copyWith(ownerId: gpId) : g)
      .toList();

  final purchased = <String, String>{};
  for (final e in next.worldState.purchasedTilesByTileKey.entries) {
    purchased[e.key] = e.value == targetGpId ? gpId : e.value;
  }

  final prospected = <String, Set<String>>{};
  for (final e in next.worldState.playerProspectedTiles.entries) {
    if (e.key == targetGpId) continue;
    prospected[e.key] = Set<String>.from(e.value);
  }
  final targetPros = next.worldState.playerProspectedTiles[targetGpId];
  if (targetPros != null && targetPros.isNotEmpty) {
    prospected.putIfAbsent(gpId, () => <String>{}).addAll(targetPros);
  }

  next = next.copyWith(
    generals: generals,
    worldState: next.worldState.copyWith(
      fleets: _remapAllFleetsFromTo(
        next.worldState.fleets,
        targetGpId,
        gpId,
      ),
      oldWorld: RegionData(
        provinces: next.worldState.oldWorld.provinces,
        units: _remapAllUnitsFromTo(
          next.worldState.oldWorld.units,
          targetGpId,
          gpId,
        ),
      ),
      newWorld: RegionData(
        provinces: next.worldState.newWorld.provinces,
        units: _remapAllUnitsFromTo(
          next.worldState.newWorld.units,
          targetGpId,
          gpId,
        ),
      ),
      purchasedTilesByTileKey: purchased,
      playerProspectedTiles: prospected,
      spyRevealTurnsByPlayer: _spyTimersWithoutPlayer(
        next.worldState.spyRevealTurnsByPlayer,
        targetGpId,
      ),
    ),
  );

  next = relocateIllegalCiviliansInChangedProvinces(
    next,
    changedProvinceIds: Set<String>.from(provinceIds),
  );

  next = next.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(
      next.worldState,
      next,
    ),
  );

  Map<String, bool> aiControl = Map<String, bool>.from(next.aiControlByGpId);
  aiControl.remove(targetGpId);

  Map<String, int> aiSeed = Map<String, int>.from(next.aiSeedByGpId);
  aiSeed.remove(targetGpId);

  Map<String, String> hidden = Map<String, String>.from(
    next.hiddenAgendaByGpId,
  );
  hidden.remove(targetGpId);

  Map<String, String> glyphs = Map<String, String>.from(
    next.politicalGlyphByPlayerId,
  );
  glyphs.remove(targetGpId);

  final overtures = next.overtureStates
      .where((o) => o.gpId != targetGpId && o.targetId != targetGpId)
      .toList();

  final relations = next.diplomacyRelations
      .where((r) => r.factionId1 != targetGpId && r.factionId2 != targetGpId)
      .toList();

  final subsidies = next.subsidyStates
      .where((s) => s.payerId != targetGpId && s.targetId != targetGpId)
      .toList();

  return next.copyWith(
    overtureStates: overtures,
    diplomacyRelations: relations,
    subsidyStates: subsidies,
    aiControlByGpId: aiControl,
    aiSeedByGpId: aiSeed,
    hiddenAgendaByGpId: hidden,
    politicalGlyphByPlayerId: glyphs,
  );
}

Game processAlliances(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn,
) {
  for (final entry in diploByPlayer.entries) {
    final gpId = entry.key;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.alliance) continue;

      final targetId = order.targetFactionId;
      if (!isGreatPower(game, targetId)) continue;

      final ids = canonicalPairIds(gpId, targetId);
      final relations = upsertRelation(
        List<DiplomacyRelation>.from(game.diplomacyRelations),
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
              )
            : existing.copyWith(
                level: RelationLevel.allied,
                score: existing.score.clamp(
                  relationScoreMinAllied,
                  relationScoreMax,
                ),
                lastInteractionTurn: turn,
              ),
      );
      game = game.copyWith(diplomacyRelations: relations);
      game = appendDiplomaticEvent(
        game,
        turn,
        DiplomaticEventType.allianceFormed,
        {gpId, targetId},
        fromFactionId: gpId,
        toFactionId: targetId,
        wasAiInitiator: isAiControlledForEvidence(game, gpId),
      );
      diploLog.i('diplomacy alliance $gpId-$targetId');
    }
  }
  return game;
}
