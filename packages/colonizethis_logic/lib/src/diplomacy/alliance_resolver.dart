import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../ai/ai_control.dart';
import '../constants.dart';
import '../dossier/evidence_rules.dart';
import '../world/civilian_ownership_legality.dart';
import 'diplomacy_relation_lookup.dart';
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
      if (order.type != DiplomaticOrderType.establishOverture) continue;
      final stage = order.overtureStage;
      if (stage != OvertureStage.joinEmpire) continue;

      final targetId = order.targetFactionId;

      final player = game.playerById(gpId);
      if (player == null) continue;

      final existing = getOverture(game, gpId, targetId);
      if (existing == null || existing.stage != OvertureStage.nap) continue;

      final rel = getRelation(game, gpId, targetId);
      final score = rel?.score ?? relationScoreNeutral;
      if (score < relationScoreMinFriendly) continue;

      if (isMinorOrTribe(game, targetId)) {
        final cost = joinEmpireCostForMinorOrTribe(game, targetId);
        if (player.treasury < cost) continue;

        game = absorbMinorOrTribeIntoGp(game, gpId, targetId, turn);
        game = appendDiplomaticEvent(
          game,
          turn,
          DiplomaticEventType.joinEmpireResolved,
          {gpId, targetId},
          fromFactionId: gpId,
          toFactionId: targetId,
          overtureStage: OvertureStage.joinEmpire,
          amount: cost,
          wasAiInitiator: isAiControlledForEvidence(game, gpId),
        );
        diploLog.i('diplomacy join empire $gpId $targetId cost=$cost');
      } else if (isGreatPower(game, targetId)) {
        if (player.techUnlocked?[kTechIdEmpireBuilding] != true) continue;
        if (!isGreatPowerNearlyDefeatedForJoinEmpire(game, targetId)) {
          continue;
        }
        final cost = joinEmpireCostForMinorOrTribe(game, targetId);
        if (player.treasury < cost) continue;

        game = absorbGreatPowerIntoGp(game, gpId, targetId);
        game = appendDiplomaticEvent(
          game,
          turn,
          DiplomaticEventType.joinEmpireResolved,
          {gpId, targetId},
          fromFactionId: gpId,
          toFactionId: targetId,
          overtureStage: OvertureStage.joinEmpire,
          amount: cost,
          wasAiInitiator: isAiControlledForEvidence(game, gpId),
        );
        diploLog.i(
          'diplomacy join empire GP $gpId absorbs $targetId cost=$cost',
        );
      }
    }
  }
  return game;
}

List<Province> _transferProvinceOwnership(
  List<Province> provinces,
  String fromId,
  String toId,
) {
  return provinces
      .map((p) => p.ownerId == fromId ? p.copyWith(ownerId: toId) : p)
      .toList();
}

List<Unit> _transferUnitOwnership(
  List<Unit> units,
  String fromId,
  String toId,
) {
  return units
      .map((u) => u.ownerId == fromId ? u.copyWith(ownerId: toId) : u)
      .toList();
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

  // Transfer provinces: ownerId targetId -> gpId
  final owProvinces = _transferProvinceOwnership(
    game.worldState.oldWorld.provinces,
    targetId,
    gpId,
  );
  final nwProvinces = _transferProvinceOwnership(
    game.worldState.newWorld.provinces,
    targetId,
    gpId,
  );

  // Transfer units: ownerId targetId -> gpId
  final owUnits = _transferUnitOwnership(
    game.worldState.oldWorld.units,
    targetId,
    gpId,
  );
  final nwUnits = _transferUnitOwnership(
    game.worldState.newWorld.units,
    targetId,
    gpId,
  );

  // Transfer fleets
  final fleets = game.worldState.fleets
      .map((f) => f.ownerId == targetId ? f.copyWith(ownerId: gpId) : f)
      .toList();

  final oldWorld = RegionData(provinces: owProvinces, units: owUnits);
  final newWorld = RegionData(provinces: nwProvinces, units: nwUnits);
  final changedProvinceIds = <String>{
    for (final p in game.worldState.oldWorld.provinces)
      if (p.ownerId == targetId) p.id,
    for (final p in game.worldState.newWorld.provinces)
      if (p.ownerId == targetId) p.id,
  };

  // Clear Spy timers for (gpId, province) where gpId now owns the province,
  // so own provinces never decay via Spy timers after absorption.
  final ownedProvinceIds = <String>{
    for (final p in owProvinces)
      if (p.ownerId == gpId) p.id,
    for (final p in nwProvinces)
      if (p.ownerId == gpId) p.id,
  };
  final updatedSpyTimers = <String, Map<String, int>>{};
  game.worldState.spyRevealTurnsByPlayer.forEach((playerId, byProv) {
    final inner = Map<String, int>.from(byProv);
    if (playerId == gpId) {
      for (final provId in ownedProvinceIds) {
        inner.remove(provId);
      }
    }
    if (inner.isNotEmpty) {
      updatedSpyTimers[playerId] = inner;
    }
  });

  var minorNations = game.minorNations;
  var tribes = game.tribes;
  if (game.minorNations.any((m) => m.id == targetId)) {
    minorNations = game.minorNations.where((m) => m.id != targetId).toList();
  }
  if (game.tribes.any((t) => t.id == targetId)) {
    tribes = game.tribes.where((t) => t.id != targetId).toList();
  }

  // Remove overture state involving this target (any GP targeting it)
  final overtures = game.overtureStates
      .where((o) => o.targetId != targetId)
      .toList();

  // Remove diplomacy relations involving this target
  final relations = game.diplomacyRelations
      .where((r) => r.factionId1 != targetId && r.factionId2 != targetId)
      .toList();

  final updatedGame = game.copyWith(
    players: players,
    worldState: game.worldState.copyWith(
      oldWorld: oldWorld,
      newWorld: newWorld,
      fleets: fleets,
      spyRevealTurnsByPlayer: updatedSpyTimers,
    ),
    minorNations: minorNations,
    tribes: tribes,
    overtureStates: overtures,
    diplomacyRelations: relations,
  );
  return relocateIllegalCiviliansInChangedProvinces(
    updatedGame,
    changedProvinceIds: changedProvinceIds,
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

  final owProvinces = _transferProvinceOwnership(
    game.worldState.oldWorld.provinces,
    targetGpId,
    gpId,
  );
  final nwProvinces = _transferProvinceOwnership(
    game.worldState.newWorld.provinces,
    targetGpId,
    gpId,
  );
  final owUnits = _transferUnitOwnership(
    game.worldState.oldWorld.units,
    targetGpId,
    gpId,
  );
  final nwUnits = _transferUnitOwnership(
    game.worldState.newWorld.units,
    targetGpId,
    gpId,
  );
  final fleets = game.worldState.fleets
      .map((f) => f.ownerId == targetGpId ? f.copyWith(ownerId: gpId) : f)
      .toList();

  final generals = game.generals
      .map((g) => g.ownerId == targetGpId ? g.copyWith(ownerId: gpId) : g)
      .toList();

  final oldWorld = RegionData(provinces: owProvinces, units: owUnits);
  final newWorld = RegionData(provinces: nwProvinces, units: nwUnits);
  final changedProvinceIds = <String>{
    for (final p in game.worldState.oldWorld.provinces)
      if (p.ownerId == targetGpId) p.id,
    for (final p in game.worldState.newWorld.provinces)
      if (p.ownerId == targetGpId) p.id,
  };

  final ownedProvinceIds = <String>{
    for (final p in owProvinces)
      if (p.ownerId == gpId) p.id,
    for (final p in nwProvinces)
      if (p.ownerId == gpId) p.id,
  };
  final updatedSpyTimers = <String, Map<String, int>>{};
  game.worldState.spyRevealTurnsByPlayer.forEach((playerId, byProv) {
    if (playerId == targetGpId) return;
    final inner = Map<String, int>.from(byProv);
    if (playerId == gpId) {
      for (final provId in ownedProvinceIds) {
        inner.remove(provId);
      }
    }
    if (inner.isNotEmpty) {
      updatedSpyTimers[playerId] = inner;
    }
  });

  final purchased = <String, String>{};
  for (final e in game.worldState.purchasedTilesByTileKey.entries) {
    purchased[e.key] = e.value == targetGpId ? gpId : e.value;
  }

  final prospected = <String, Set<String>>{};
  for (final e in game.worldState.playerProspectedTiles.entries) {
    if (e.key == targetGpId) continue;
    prospected[e.key] = Set<String>.from(e.value);
  }
  final targetPros = game.worldState.playerProspectedTiles[targetGpId];
  if (targetPros != null && targetPros.isNotEmpty) {
    prospected.putIfAbsent(gpId, () => <String>{}).addAll(targetPros);
  }

  Map<String, bool> aiControl = Map<String, bool>.from(game.aiControlByGpId);
  aiControl.remove(targetGpId);

  Map<String, int> aiSeed = Map<String, int>.from(game.aiSeedByGpId);
  aiSeed.remove(targetGpId);

  Map<String, String> hidden = Map<String, String>.from(
    game.hiddenAgendaByGpId,
  );
  hidden.remove(targetGpId);

  Map<String, String> glyphs = Map<String, String>.from(
    game.politicalGlyphByPlayerId,
  );
  glyphs.remove(targetGpId);

  final overtures = game.overtureStates
      .where((o) => o.gpId != targetGpId && o.targetId != targetGpId)
      .toList();

  final relations = game.diplomacyRelations
      .where((r) => r.factionId1 != targetGpId && r.factionId2 != targetGpId)
      .toList();

  final subsidies = game.subsidyStates
      .where((s) => s.payerId != targetGpId && s.targetId != targetGpId)
      .toList();

  final updatedGame = game.copyWith(
    players: players,
    generals: generals,
    worldState: game.worldState.copyWith(
      oldWorld: oldWorld,
      newWorld: newWorld,
      fleets: fleets,
      spyRevealTurnsByPlayer: updatedSpyTimers,
      purchasedTilesByTileKey: purchased,
      playerProspectedTiles: prospected,
    ),
    overtureStates: overtures,
    diplomacyRelations: relations,
    subsidyStates: subsidies,
    aiControlByGpId: aiControl,
    aiSeedByGpId: aiSeed,
    hiddenAgendaByGpId: hidden,
    politicalGlyphByPlayerId: glyphs,
  );
  return relocateIllegalCiviliansInChangedProvinces(
    updatedGame,
    changedProvinceIds: changedProvinceIds,
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
