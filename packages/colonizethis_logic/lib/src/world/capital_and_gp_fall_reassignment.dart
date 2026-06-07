part of 'capital_and_gp_fall.dart';

Game applyCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  Game game = state;
  for (final player in state.players) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null || player.capitalTile == null) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final regionTopology = topologyByRegion?[regionId] ?? topology;
    final province = state.worldState.tryGetProvince(capProvinceId);
    if (province == null) continue;
    if (province.ownerId == player.id) continue;

    final eligibility = evaluateCapitalReassignmentEligibility(
      state: game,
      playerId: player.id,
      regionId: regionId,
      regionTopology: regionTopology,
    );
    if (!eligibility.eligible) {
      game = game.mapPlayers(
        (p) => p.id != player.id
            ? p
            : p.copyWith(capitalProvinceId: null, capitalTile: null),
      );
      logicLog.i(
        'player ${player.id} lost capital and has no provinces in $regionId; capital cleared',
      );
      continue;
    }

    final newProvinceId = eligibility.candidateProvinceId;
    if (newProvinceId == null || newProvinceId.isEmpty) {
      final msg =
          'capital reassignment: missing deterministic candidate in region $regionId for player ${player.id}';
      final err = StateError(msg);
      logicLog.e(msg, error: err, stackTrace: StackTrace.current);
      throw CapitalReassignmentFatalError(msg, err);
    }
    final newProvince = game.worldState.tryGetProvince(newProvinceId);
    if (newProvince == null) {
      final msg =
          'capital reassignment: province $newProvinceId not found in region $regionId for player ${player.id}';
      logicLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
      throw CapitalReassignmentFatalError(msg);
    }

    final rawTown = newProvince.townTileKey;
    if (rawTown == null || rawTown.isEmpty) {
      final msg =
          'capital reassignment: missing townTileKey for province $newProvinceId player ${player.id}';
      final err = StateError(msg);
      logicLog.e(msg, error: err, stackTrace: StackTrace.current);
      throw CapitalReassignmentFatalError(msg, err);
    }

    late final CapitalTile tile;
    try {
      tile = CapitalTile.parseTownTileKey(rawTown, newProvinceId);
    } catch (e, st) {
      final msg =
          'capital reassignment: invalid townTileKey for province $newProvinceId player ${player.id} raw="$rawTown"';
      logicLog.e(msg, error: e, stackTrace: st);
      throw CapitalReassignmentFatalError(
        'Invalid townTileKey for province $newProvinceId (player ${player.id}): $e',
        e,
      );
    }

    try {
      game = setCapitalForReassignment(
        game: game,
        playerId: player.id,
        provinceId: newProvinceId,
        tile: tile,
      );
      game = game.copyWith(
        worldState: applyGreatPowerCapitalProvinceTownDevelopment(
          game.worldState,
          regionId,
          newProvinceId,
        ),
      );
      final newCapKey = tile.toTileKey();
      final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
        game,
        tileMapByRegion,
        [newCapKey],
      );
      game = strip.$1;
      final stripMaps = strip.$2;
      if (stripMaps != null && tileMapByRegion != null) {
        for (final e in stripMaps.entries) {
          tileMapByRegion[e.key] = e.value;
        }
      }
      logicLog.i(
        'player ${player.id} capital reassigned to $newProvinceId ($newCapKey) after loss',
      );
    } catch (e, st) {
      final msg =
          'capital reassignment: failed to apply new capital for ${player.id}';
      logicLog.e(msg, error: e, stackTrace: st);
      rethrow;
    }
  }
  return game;
}

/// Runtime capital reassignment for **Minor Nations** and **Tribes** after combat
/// (and after debug `/flip_province`). Parallel to [applyCapitalReassignmentAfterCombat]
/// for Great Powers, but updates only `capitalProvinceId` and `capitalTile` on the
/// faction entry; no port/road wiring, no `townDevelopmentLevel` mutation, no
/// `townTileKey` mutation. Uses the same faction-agnostic
/// `pickCapitalProvinceIdForReassignment(ownedProvinceIds, topology)` picker.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game applyFactionCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  Game game = state;

  for (final minor in state.minorNations) {
    final capProvinceId = minor.capitalProvinceId;
    if (capProvinceId == null || minor.capitalTile == null) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final regionTopology = topologyByRegion?[regionId] ?? topology;
    final province = state.worldState.tryGetProvince(capProvinceId);
    if (province == null) continue;
    if (province.ownerId == minor.id) continue;

    final eligibility = evaluateCapitalReassignmentEligibility(
      state: game,
      playerId: minor.id,
      regionId: regionId,
      regionTopology: regionTopology,
    );
    if (!eligibility.eligible) {
      final updatedMinors = game.minorNations
          .map(
            (m) => m.id != minor.id
                ? m
                : MinorNation(
                    id: m.id,
                    displayName: m.displayName,
                    effectiveMilitaryLevel: m.effectiveMilitaryLevel,
                  ),
          )
          .toList();
      game = game.copyWith(minorNations: updatedMinors);
      logicLog.i(
        'minor ${minor.id} lost capital and has no provinces in $regionId; capital cleared',
      );
      continue;
    }

    final tile = _resolveReassignmentTileOrThrow(
      game: game,
      eligibility: eligibility,
      regionId: regionId,
      factionLabel: 'minor ${minor.id}',
    );
    final newProvinceId = eligibility.candidateProvinceId!;
    game = setCapitalForMinorReassignment(
      game: game,
      minorId: minor.id,
      provinceId: newProvinceId,
      tile: tile,
    );
    logicLog.i(
      'minor ${minor.id} capital reassigned to $newProvinceId (${tile.toTileKey()}) after loss',
    );
  }

  for (final tribe in state.tribes) {
    final capProvinceId = tribe.capitalProvinceId;
    if (capProvinceId == null || tribe.capitalTile == null) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final regionTopology = topologyByRegion?[regionId] ?? topology;
    final province = state.worldState.tryGetProvince(capProvinceId);
    if (province == null) continue;
    if (province.ownerId == tribe.id) continue;

    final eligibility = evaluateCapitalReassignmentEligibility(
      state: game,
      playerId: tribe.id,
      regionId: regionId,
      regionTopology: regionTopology,
    );
    if (!eligibility.eligible) {
      final updatedTribes = game.tribes
          .map(
            (t) => t.id != tribe.id
                ? t
                : Tribe(
                    id: t.id,
                    displayName: t.displayName,
                    effectiveMilitaryLevel: t.effectiveMilitaryLevel,
                  ),
          )
          .toList();
      game = game.copyWith(tribes: updatedTribes);
      logicLog.i(
        'tribe ${tribe.id} lost capital and has no provinces in $regionId; capital cleared',
      );
      continue;
    }

    final tile = _resolveReassignmentTileOrThrow(
      game: game,
      eligibility: eligibility,
      regionId: regionId,
      factionLabel: 'tribe ${tribe.id}',
    );
    final newProvinceId = eligibility.candidateProvinceId!;
    game = setCapitalForTribeReassignment(
      game: game,
      tribeId: tribe.id,
      provinceId: newProvinceId,
      tile: tile,
    );
    logicLog.i(
      'tribe ${tribe.id} capital reassigned to $newProvinceId (${tile.toTileKey()}) after loss',
    );
  }

  return game;
}

CapitalTile _resolveReassignmentTileOrThrow({
  required Game game,
  required CapitalReassignmentEligibility eligibility,
  required String regionId,
  required String factionLabel,
}) {
  final newProvinceId = eligibility.candidateProvinceId;
  if (newProvinceId == null || newProvinceId.isEmpty) {
    final msg =
        'capital reassignment: missing deterministic candidate in region $regionId for $factionLabel';
    final err = StateError(msg);
    logicLog.e(msg, error: err, stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg, err);
  }
  final newProvince = game.worldState.tryGetProvince(newProvinceId);
  if (newProvince == null) {
    final msg =
        'capital reassignment: province $newProvinceId not found in region $regionId for $factionLabel';
    logicLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg);
  }
  final rawTown = newProvince.townTileKey;
  if (rawTown == null || rawTown.isEmpty) {
    final msg =
        'capital reassignment: missing townTileKey for province $newProvinceId $factionLabel';
    final err = StateError(msg);
    logicLog.e(msg, error: err, stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg, err);
  }
  try {
    return CapitalTile.parseTownTileKey(rawTown, newProvinceId);
  } catch (e, st) {
    final msg =
        'capital reassignment: invalid townTileKey for province $newProvinceId $factionLabel raw="$rawTown"';
    logicLog.e(msg, error: e, stackTrace: st);
    throw CapitalReassignmentFatalError(
      'Invalid townTileKey for province $newProvinceId ($factionLabel): $e',
      e,
    );
  }
}
