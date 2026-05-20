import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../setup/capital_choice.dart';
import '../setup/town_capital_occupancy.dart';
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
    game = game.copyWith(worldState: nextWorldState).mapPlayers(
      (p) => p.id == playerId
          ? p.copyWith(capitalProvinceId: null, capitalTile: null)
          : p,
    );
  }

  return game;
}
