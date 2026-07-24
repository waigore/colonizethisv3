import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_world/src/world/civilian_ownership_legality.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'faction_absorption_cleanup.dart';

enum FactionAbsorptionKind { minorOrTribe, greatPower }

List<String> sortedFullProvinceIdsOwnedBy(Game game, String ownerId) {
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

List<Fleet> remapAllFleetsFromTo(
  List<Fleet> fleets,
  String fromId,
  String toId,
) {
  return fleets
      .map((f) => f.ownerId == fromId ? f.copyWith(ownerId: toId) : f)
      .toList();
}

List<Unit> remapAllUnitsFromTo(List<Unit> units, String fromId, String toId) {
  return units
      .map((u) => u.ownerId == fromId ? u.copyWith(ownerId: toId) : u)
      .toList();
}

Map<String, Map<String, int>> spyTimersWithoutPlayer(
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

Game absorbFactionIntoGp(
  Game game, {
  required String gpId,
  required String absorbedFactionId,
  required FactionAbsorptionKind kind,
}) {
  final cost = joinEmpireCostForMinorOrTribe(game, absorbedFactionId);
  var players = List<Player>.from(game.players);

  // Shared id → row index (Refs #3562) replacing the bespoke index scans
  // (originally Refs #2394 Category C). Last-wins on duplicate ids matches the
  // prior single-pass assignment.
  final playerIndexById = indexByKey(players, (p) => p.id);
  if (kind == FactionAbsorptionKind.greatPower) {
    final gpIdx = playerIndexById[gpId] ?? -1;
    final targetIdx = playerIndexById[absorbedFactionId] ?? -1;
    if (gpIdx < 0 || targetIdx < 0) return game;
    players = debitPlayerTreasury(players, gpIdx, cost);
    players.removeAt(targetIdx);
  } else {
    final gpIdx = playerIndexById[gpId] ?? -1;
    players = debitPlayerTreasury(players, gpIdx, cost);
  }

  final provinceIds = sortedFullProvinceIdsOwnedBy(game, absorbedFactionId);
  var next = game.withPlayers(players);
  final bulk = applyBulkCanonicalProvinceOwnershipTransfers(
    next,
    provinceIdsInOrder: provinceIds,
    oldOwnerId: absorbedFactionId,
    newOwnerId: gpId,
    relocateIllegalCivilians: false,
  );
  next = bulk.game;

  // Great Power absorption remaps GP-only game fields. Minor/Tribe targets are
  // not GPs: Join Empire mandates province/unit/fleet transfer and relation
  // cleanup, but does not require GP-only cleanups on the minor path
  // (Refs #4028 extract under 200-line guideline).
  next = kind == FactionAbsorptionKind.greatPower
      ? remapAbsorbedGreatPowerAssets(next, gpId, absorbedFactionId)
      : remapAbsorbedMinorOrTribeAssets(next, gpId, absorbedFactionId);

  next = relocateIllegalCiviliansInChangedProvinces(
    next,
    changedProvinceIds: Set<String>.from(provinceIds),
  );

  next = next.withWorldState(
    reconcileArmiesAfterUnitsChanged(next.worldState, next),
  );

  return kind == FactionAbsorptionKind.minorOrTribe
      ? cleanupAfterMinorOrTribeAbsorb(next, absorbedFactionId)
      : cleanupAfterGreatPowerAbsorb(next, absorbedFactionId);
}

Game remapAbsorbedGreatPowerAssets(
  Game next,
  String gpId,
  String absorbedFactionId,
) {
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
    fleets: remapAllFleetsFromTo(
      next.worldState.fleets,
      absorbedFactionId,
      gpId,
    ),
    purchasedTilesByTileKey: purchased,
    playerProspectedTiles: prospected,
    spyRevealTurnsByPlayer: spyTimersWithoutPlayer(
      next.worldState.spyRevealTurnsByPlayer,
      absorbedFactionId,
    ),
  );
  ws = ws.mapBothRegionUnits(
    (_, units) => remapAllUnitsFromTo(units, absorbedFactionId, gpId),
  );
  // Atomic multi-field mutation (generals + worldState); kept as raw
  // copyWith per Issue #2836 AC 6 single-field-only helper scope.
  return next.copyWith(generals: generals, worldState: ws);
}

Game remapAbsorbedMinorOrTribeAssets(
  Game next,
  String gpId,
  String absorbedFactionId,
) {
  var ws = next.worldState.copyWith(
    fleets: remapAllFleetsFromTo(
      next.worldState.fleets,
      absorbedFactionId,
      gpId,
    ),
    spyRevealTurnsByPlayer: spyTimersWithoutPlayer(
      next.worldState.spyRevealTurnsByPlayer,
      absorbedFactionId,
    ),
  );
  ws = ws.mapBothRegionUnits(
    (_, units) => remapAllUnitsFromTo(units, absorbedFactionId, gpId),
  );
  return next.withWorldState(ws);
}
