import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/army_migration.dart';
import '../world/civilian_ownership_legality.dart';
import '../world/province_lookup.dart';
import '../world/province_ownership_transfer.dart';
import 'diplomacy_relation_lookup.dart';

/// Join-Empire absorption shared between minor/tribe and GP targets.
/// SPEC/game/diplomacy.md. Refs #2071.
abstract final class FactionAbsorptionEngine {
  FactionAbsorptionEngine._();

  /// Transfers all provinces, units, and fleets owned by [targetId] to [gpId],
  /// deducts Join Empire cost from GP treasury, removes the Minor/Tribe and
  /// cleans overtures/relations.
  static Game absorbMinorOrTribeIntoGp(
    Game game,
    String gpId,
    String targetId,
    int turn,
  ) {
    return _absorbIntoGp(
      game,
      gpId: gpId,
      absorbedFactionId: targetId,
      kind: _AbsorptionKind.minorOrTribe,
    );
  }

  /// Absorbs a nearly-defeated GP [targetGpId] into [gpId] (player removed).
  static Game absorbGreatPowerIntoGp(
    Game game,
    String gpId,
    String targetGpId,
  ) {
    return _absorbIntoGp(
      game,
      gpId: gpId,
      absorbedFactionId: targetGpId,
      kind: _AbsorptionKind.greatPower,
    );
  }
}

enum _AbsorptionKind { minorOrTribe, greatPower }

List<String> _sortedFullProvinceIdsOwnedBy(Game game, String ownerId) {
  final ids = <String>[];
  for (final p in game.worldState.allProvinces()) {
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
      .map((f) => f.ownerId == fromId ? f.copyWith(ownerId: toId) : f)
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

Game _absorbIntoGp(
  Game game, {
  required String gpId,
  required String absorbedFactionId,
  required _AbsorptionKind kind,
}) {
  final cost = joinEmpireCostForMinorOrTribe(game, absorbedFactionId);
  var players = List<Player>.from(game.players);

  if (kind == _AbsorptionKind.greatPower) {
    // Single pass replaces two indexWhere scans (Refs #2394 Category C).
    var gpIdx = -1;
    var targetIdx = -1;
    for (var i = 0; i < players.length; i++) {
      final id = players[i].id;
      if (id == gpId) gpIdx = i;
      if (id == absorbedFactionId) targetIdx = i;
    }
    if (gpIdx < 0 || targetIdx < 0) return game;
    players[gpIdx] = players[gpIdx].copyWith(
      treasury: players[gpIdx].treasury - cost,
    );
    players.removeAt(targetIdx);
  } else {
    var gpIdx = -1;
    for (var i = 0; i < players.length; i++) {
      if (players[i].id == gpId) {
        gpIdx = i;
        break;
      }
    }
    if (gpIdx >= 0) {
      players[gpIdx] = players[gpIdx].copyWith(
        treasury: players[gpIdx].treasury - cost,
      );
    }
  }

  final provinceIds = _sortedFullProvinceIdsOwnedBy(game, absorbedFactionId);
  var next = game.copyWith(players: players);
  final bulk = applyBulkCanonicalProvinceOwnershipTransfers(
    next,
    provinceIdsInOrder: provinceIds,
    oldOwnerId: absorbedFactionId,
    newOwnerId: gpId,
    relocateIllegalCivilians: false,
  );
  next = bulk.game;

  // Great Power absorption remaps GP-only game fields (`generals`,
  // `purchasedTilesByTileKey`, `playerProspectedTiles`, AI metadata maps,
  // `politicalGlyphByPlayerId`, `subsidyStates`). Minor/Tribe targets are not
  // GPs: `SPEC/game/diplomacy.md` Join Empire mandates province/unit/fleet
  // transfer and relation cleanup for them, but does **not** require those
  // GP-only cleanups on the minor path—so the branch below is intentionally
  // GP-only (avoids conflating nation ids with player-owned persistence).
  if (kind == _AbsorptionKind.greatPower) {
    final generals = next.generals
        .map(
          (g) => g.ownerId == absorbedFactionId ? g.copyWith(ownerId: gpId) : g,
        )
        .toList();

    final purchased = <String, String>{};
    for (final e in next.worldState.purchasedTilesByTileKey.entries) {
      purchased[e.key] = e.value == absorbedFactionId ? gpId : e.value;
    }

    final prospected = <String, Set<String>>{};
    for (final e in next.worldState.playerProspectedTiles.entries) {
      if (e.key == absorbedFactionId) continue;
      prospected[e.key] = Set<String>.from(e.value);
    }
    final targetPros = next.worldState.playerProspectedTiles[absorbedFactionId];
    if (targetPros != null && targetPros.isNotEmpty) {
      prospected.putIfAbsent(gpId, () => <String>{}).addAll(targetPros);
    }

    var ws = next.worldState.copyWith(
      fleets: _remapAllFleetsFromTo(
        next.worldState.fleets,
        absorbedFactionId,
        gpId,
      ),
      purchasedTilesByTileKey: purchased,
      playerProspectedTiles: prospected,
      spyRevealTurnsByPlayer: _spyTimersWithoutPlayer(
        next.worldState.spyRevealTurnsByPlayer,
        absorbedFactionId,
      ),
    );
    ws = ws.mapBothRegionUnits(
      (_, units) => _remapAllUnitsFromTo(units, absorbedFactionId, gpId),
    );
    next = next.copyWith(generals: generals, worldState: ws);
  } else {
    var ws = next.worldState.copyWith(
      fleets: _remapAllFleetsFromTo(
        next.worldState.fleets,
        absorbedFactionId,
        gpId,
      ),
      spyRevealTurnsByPlayer: _spyTimersWithoutPlayer(
        next.worldState.spyRevealTurnsByPlayer,
        absorbedFactionId,
      ),
    );
    ws = ws.mapBothRegionUnits(
      (_, units) => _remapAllUnitsFromTo(units, absorbedFactionId, gpId),
    );
    next = next.copyWith(worldState: ws);
  }

  next = relocateIllegalCiviliansInChangedProvinces(
    next,
    changedProvinceIds: Set<String>.from(provinceIds),
  );

  next = next.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(next.worldState, next),
  );

  if (kind == _AbsorptionKind.minorOrTribe) {
    var minorNations = next.minorNations;
    var tribes = next.tribes;
    if (next.minorNations.any((m) => m.id == absorbedFactionId)) {
      minorNations = next.minorNations
          .where((m) => m.id != absorbedFactionId)
          .toList();
    }
    if (next.tribes.any((t) => t.id == absorbedFactionId)) {
      tribes = next.tribes.where((t) => t.id != absorbedFactionId).toList();
    }

    final overtures = next.overtureStates
        .where((o) => o.targetId != absorbedFactionId)
        .toList();

    final relations = next.diplomacyRelations
        .where(
          (r) =>
              r.factionId1 != absorbedFactionId &&
              r.factionId2 != absorbedFactionId,
        )
        .toList();

    return next.copyWith(
      minorNations: minorNations,
      tribes: tribes,
      overtureStates: overtures,
      diplomacyRelations: relations,
    );
  }

  final aiControl = Map<String, bool>.from(next.aiControlByGpId)
    ..remove(absorbedFactionId);
  final aiSeed = Map<String, int>.from(next.aiSeedByGpId)
    ..remove(absorbedFactionId);
  final hidden = Map<String, String>.from(next.hiddenAgendaByGpId)
    ..remove(absorbedFactionId);
  final glyphs = Map<String, String>.from(next.politicalGlyphByPlayerId)
    ..remove(absorbedFactionId);

  final overtures = next.overtureStates
      .where(
        (o) => o.gpId != absorbedFactionId && o.targetId != absorbedFactionId,
      )
      .toList();

  final relations = next.diplomacyRelations
      .where(
        (r) =>
            r.factionId1 != absorbedFactionId &&
            r.factionId2 != absorbedFactionId,
      )
      .toList();

  final subsidies = next.subsidyStates
      .where(
        (s) =>
            s.payerId != absorbedFactionId && s.targetId != absorbedFactionId,
      )
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
