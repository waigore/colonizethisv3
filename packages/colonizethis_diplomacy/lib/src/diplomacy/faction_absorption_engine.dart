import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/src/world/civilian_ownership_legality.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';

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

  /// Marks Tribe [tribeId] as a colony of [gpId] via Tribe Join Empire.
  ///
  /// Unlike [absorbMinorOrTribeIntoGp], the Tribe is **not** absorbed: it stays
  /// in [Game.tribes], its provinces/units/fleets are not transferred, and its
  /// overtures/relations are preserved. Only the Join Empire cost is deducted
  /// from the GP treasury and a [ColonyState] is recorded (one per Tribe; an
  /// existing colony record for the same Tribe is replaced).
  /// SPEC/game/diplomacy.md § GP–Minor/Tribe Rules (Join Empire → colony).
  static Game markTribeAsColony(
    Game game,
    String gpId,
    String tribeId,
    int turn,
  ) {
    final cost = joinEmpireCostForMinorOrTribe(game, tribeId);
    final players = List<Player>.from(game.players);
    final gpIdx = indexByKey(players, (p) => p.id)[gpId] ?? -1;
    if (gpIdx >= 0) {
      players[gpIdx] = players[gpIdx].copyWith(
        treasury: players[gpIdx].treasury - cost,
      );
    }

    final colonies = game.colonyStates
        .where((c) => c.tribeId != tribeId)
        .toList()
      ..add(
        ColonyState(tribeId: tribeId, colonyOfGpId: gpId, sinceTurn: turn),
      );

    return game.withPlayers(players).copyWith(colonyStates: colonies);
  }
}

enum _AbsorptionKind { minorOrTribe, greatPower }

List<String> _sortedFullProvinceIdsOwnedBy(Game game, String ownerId) {
  // Reads the owned provinces from the shared read-only ProvinceOwnerCache
  // projection (Phase 6b, SPEC/program/worldstate-projection.md; Refs #3393)
  // instead of a full-world `allProvinces` owner scan. The result is sorted, so
  // the projection's iteration order is irrelevant to the returned ids.
  final ids = ProvinceOwnerCache.of(
    game.worldState,
  ).provincesOwnedBy(ownerId).map((p) => p.id).toList();
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

  // Shared id → row index (Refs #3562) replacing the bespoke index scans
  // (originally Refs #2394 Category C). Last-wins on duplicate ids matches the
  // prior single-pass assignment.
  final playerIndexById = indexByKey(players, (p) => p.id);
  if (kind == _AbsorptionKind.greatPower) {
    final gpIdx = playerIndexById[gpId] ?? -1;
    final targetIdx = playerIndexById[absorbedFactionId] ?? -1;
    if (gpIdx < 0 || targetIdx < 0) return game;
    players[gpIdx] = players[gpIdx].copyWith(
      treasury: players[gpIdx].treasury - cost,
    );
    players.removeAt(targetIdx);
  } else {
    final gpIdx = playerIndexById[gpId] ?? -1;
    if (gpIdx >= 0) {
      players[gpIdx] = players[gpIdx].copyWith(
        treasury: players[gpIdx].treasury - cost,
      );
    }
  }

  final provinceIds = _sortedFullProvinceIdsOwnedBy(game, absorbedFactionId);
  var next = game.withPlayers(players);
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
    // Atomic multi-field mutation (generals + worldState); kept as raw
    // copyWith per Issue #2836 AC 6 single-field-only helper scope.
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
    next = next.withWorldState(ws);
  }

  next = relocateIllegalCiviliansInChangedProvinces(
    next,
    changedProvinceIds: Set<String>.from(provinceIds),
  );

  next = next.withWorldState(
    reconcileArmiesAfterUnitsChanged(next.worldState, next),
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

    // Canonical full-faction overture teardown (Refs #3562 AC1) replaces the
    // prior inline `targetId == absorbedFactionId` filter. Minor/Tribe targets
    // never originate overtures, so clearing either side is equivalent here.
    final overtures =
        clearOverturesInvolvingFaction(next, absorbedFactionId).game
            .overtureStates;

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

  // Canonical full-faction overture teardown (Refs #3562 AC1) replaces the prior
  // inline `gpId == absorbedFactionId || targetId == absorbedFactionId` filter.
  final overtures =
      clearOverturesInvolvingFaction(next, absorbedFactionId).game
          .overtureStates;

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

  // When the removed GP held colonies, those Tribes lose their suzerain and
  // become independent again (their favoured trading partner reverts to the
  // relation-based lookup). Every boycott the removed GP issued, and every
  // boycott directed at it, is meaningless once it leaves the game and is
  // cleared. SPEC/game/diplomacy.md § GP–Tribe Rules (Join Empire → colony,
  // Boycott) — colony relationship ends when the colonizing GP is removed
  // (Refs #3753 R5.5 / R6.4).
  final colonies = next.colonyStates
      .where((c) => c.colonyOfGpId != absorbedFactionId)
      .toList();
  final boycotts = next.boycottStates
      .where(
        (b) =>
            b.gpId != absorbedFactionId && b.targetGpId != absorbedFactionId,
      )
      .toList();

  return next.copyWith(
    overtureStates: overtures,
    diplomacyRelations: relations,
    subsidyStates: subsidies,
    colonyStates: colonies,
    boycottStates: boycotts,
    aiControlByGpId: aiControl,
    aiSeedByGpId: aiSeed,
    hiddenAgendaByGpId: hidden,
    politicalGlyphByPlayerId: glyphs,
  );
}
