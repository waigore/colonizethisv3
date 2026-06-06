import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_reassignment.dart';
import 'town_capital_tile_strip.dart';
import 'game_world_mutations.dart';
import 'player_state_pipeline.dart';
import 'port_seaboard_registry_key.dart';
import 'province_lookup.dart';
import 'capital_reassignment_fatal.dart';

class CapitalReassignmentEligibility {
  const CapitalReassignmentEligibility({
    required this.eligible,
    required this.reasonCode,
    required this.ownedProvinceIdsInRegion,
    this.candidateProvinceId,
  });

  final bool eligible;
  final String reasonCode;
  final List<String> ownedProvinceIdsInRegion;
  final String? candidateProvinceId;
}

CapitalReassignmentEligibility evaluateCapitalReassignmentEligibility({
  required Game state,
  required String playerId,
  required String regionId,
  required MapTopology regionTopology,
  String? excludedProvinceId,
}) {
  final region = regionDataForId(state.worldState, regionId);
  if (region == null) {
    return const CapitalReassignmentEligibility(
      eligible: false,
      reasonCode: 'region_not_found',
      ownedProvinceIdsInRegion: <String>[],
    );
  }

  final ownedInRegion = region.provinces
      .where(
        (p) =>
            p.ownerId == playerId &&
            (excludedProvinceId == null || p.id != excludedProvinceId),
      )
      .map((p) => p.id)
      .toList(growable: false);
  if (ownedInRegion.isEmpty) {
    return const CapitalReassignmentEligibility(
      eligible: false,
      reasonCode: 'no_owned_provinces_in_region',
      ownedProvinceIdsInRegion: <String>[],
    );
  }

  final candidateProvinceId = pickCapitalProvinceIdForReassignment(
    ownedInRegion,
    regionTopology,
  );
  return CapitalReassignmentEligibility(
    eligible: true,
    reasonCode: 'eligible',
    ownedProvinceIdsInRegion: ownedInRegion,
    candidateProvinceId: candidateProvinceId,
  );
}

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

/// Terminal fall for **Minor Nations** and **Tribes** after combat resolution
/// and capital reassignment. Parallel to [applyGreatPowerFall] but the
/// eligibility check is **no owned provinces in the original capital region**
/// (matches the `evaluateCapitalReassignmentEligibility`
/// `no_owned_provinces_in_region` branch). When the trigger fires, all
/// provinces previously owned by the falling faction are transferred to the
/// faction that currently owns its lost capital province, the faction is
/// removed from `Game.minorNations` / `Game.tribes`, and any remaining units
/// and fleets owned by the falling faction are removed from world state.
/// SPEC/game/capital-and-connectivity § Minor Nation and Tribe terminal fall.
Game applyFactionTerminalFall(
  Game state, {
  required Map<String, String?> previousCapitalByMinor,
  required Map<String, String?> previousCapitalByTribe,
}) {
  var game = state;

  for (final minorId in previousCapitalByMinor.keys.toList()..sort()) {
    final prevCapitalId = previousCapitalByMinor[minorId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;
    if (!game.minorNations.any((m) => m.id == minorId)) continue;
    final result = _applyTerminalFallForFaction(
      game: game,
      factionId: minorId,
      previousCapitalId: prevCapitalId,
      factionLabel: 'minor',
      removeFaction: (g) => g.copyWith(
        minorNations: g.minorNations.where((m) => m.id != minorId).toList(),
      ),
    );
    game = result;
  }

  for (final tribeId in previousCapitalByTribe.keys.toList()..sort()) {
    final prevCapitalId = previousCapitalByTribe[tribeId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;
    if (!game.tribes.any((t) => t.id == tribeId)) continue;
    final result = _applyTerminalFallForFaction(
      game: game,
      factionId: tribeId,
      previousCapitalId: prevCapitalId,
      factionLabel: 'tribe',
      removeFaction: (g) =>
          g.copyWith(tribes: g.tribes.where((t) => t.id != tribeId).toList()),
    );
    game = result;
  }

  return game;
}

Game _applyTerminalFallForFaction({
  required Game game,
  required String factionId,
  required String previousCapitalId,
  required String factionLabel,
  required Game Function(Game) removeFaction,
}) {
  final prevCapital = game.worldState.tryGetProvince(previousCapitalId);
  if (prevCapital == null) return game;
  final conquerorId = prevCapital.ownerId;
  if (conquerorId == null || conquerorId.isEmpty || conquerorId == factionId) {
    return game;
  }
  final originalRegionId = ProvinceId.regionIdFrom(previousCapitalId);
  final originalRegion = regionDataForId(game.worldState, originalRegionId);
  if (originalRegion == null) return game;
  final hasProvinceInOriginalRegion = originalRegion.provinces.any(
    (p) => p.ownerId == factionId,
  );
  if (hasProvinceInOriginalRegion) return game;

  RegionData transferRegion(RegionData region) {
    final updatedProvinces = region.provinces
        .map(
          (p) => p.ownerId == factionId ? p.copyWith(ownerId: conquerorId) : p,
        )
        .toList();
    final remainingUnits = region.units
        .where((u) => u.ownerId != factionId)
        .toList();
    return RegionData(provinces: updatedProvinces, units: remainingUnits);
  }

  final updatedWorldState = game.worldState.mapBothRegions(
    (_, region) => transferRegion(region),
  );
  final remainingFleets = game.worldState.fleets
      .where((f) => f.ownerId != factionId)
      .toList();
  final nextWorldState = updatedWorldState.copyWith(fleets: remainingFleets);
  var next = game.withWorldState(nextWorldState);
  next = removeFaction(next);
  logicLog.i(
    '$factionLabel $factionId fell after capital loss; '
    'provinces and assets transferred to $conquerorId',
  );
  return next;
}

Game applyGreatPowerFall(
  Game state,
  Map<String, String?> previousCapitalByPlayer,
) {
  var game = state;

  final provinceOwnerById = <String, String?>{
    for (final p in allProvinces(game.worldState)) p.id: p.ownerId,
  };

  final portsByProvince = <String, List<String>>{};
  game.worldState.portsByProvinceSeaboard.forEach((key, _) {
    final decoded = decodePortSeaboardRegistryKey(key);
    if (decoded == null || !decoded.isPrefixedKey) return;
    portsByProvince.putIfAbsent(decoded.fullProvinceId, () => []).add(key);
  });

  for (final player in game.players) {
    final playerId = player.id;
    final prevCapitalId = previousCapitalByPlayer[playerId];
    if (prevCapitalId == null || prevCapitalId.isEmpty) continue;

    final prevCapitalOwner = provinceOwnerById[prevCapitalId];
    if (prevCapitalOwner == null || prevCapitalOwner == playerId) {
      continue;
    }

    var hasPortProvince = false;
    provinceOwnerById.forEach((provId, ownerId) {
      if (ownerId == playerId && portsByProvince.containsKey(provId)) {
        hasPortProvince = true;
      }
    });
    if (hasPortProvince) continue;

    final conquerorId = prevCapitalOwner;

    RegionData transferRegion(RegionData region) {
      final updatedProvinces = region.provinces
          .map(
            (p) => p.ownerId == playerId ? p.copyWith(ownerId: conquerorId) : p,
          )
          .toList();
      final remainingUnits = region.units
          .where((u) => u.ownerId != playerId)
          .toList();
      return RegionData(provinces: updatedProvinces, units: remainingUnits);
    }

    final updatedWorldState = game.worldState.mapBothRegions(
      (_, region) => transferRegion(region),
    );

    final remainingFleets = game.worldState.fleets
        .where((f) => f.ownerId != playerId)
        .toList();

    final nextWorldState = updatedWorldState.copyWith(fleets: remainingFleets);
    game = game
        .withWorldState(nextWorldState)
        .mapPlayers(
          (p) => p.id == playerId
              ? p.copyWith(capitalProvinceId: null, capitalTile: null)
              : p,
        );
  }

  return game;
}
