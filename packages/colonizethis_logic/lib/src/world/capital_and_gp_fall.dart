import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../setup/capital_choice.dart';
import '../setup/town_capital_occupancy.dart';
import 'player_state_pipeline.dart';
import 'province_lookup.dart';
import 'capital_reassignment_fatal.dart';

final _log = packageLogger();

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
    final region = regionDataForId(state.worldState, regionId);
    if (region == null) continue;
    final province = region.provinces
        .where((p) => p.id == capProvinceId)
        .firstOrNull;
    if (province == null) continue;
    if (province.ownerId == player.id) continue;

    final ownedInRegion = region.provinces
        .where((p) => p.ownerId == player.id)
        .map((p) => p.id)
        .toList();
    if (ownedInRegion.isEmpty) {
      game = game.mapPlayers(
        (p) => p.id != player.id
            ? p
            : p.copyWith(capitalProvinceId: null, capitalTile: null),
      );
      _log.i(
        'player ${player.id} lost capital and has no provinces in $regionId; capital cleared',
      );
      continue;
    }

    final newProvinceId = pickCapitalProvinceIdForReassignment(
      ownedInRegion,
      regionTopology,
    );
    final newProvince = region.provinces
        .where((p) => p.id == newProvinceId)
        .firstOrNull;
    if (newProvince == null) {
      final msg =
          'capital reassignment: province $newProvinceId not found in region $regionId for player ${player.id}';
      _log.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
      throw CapitalReassignmentFatalError(msg);
    }

    final rawTown = newProvince.townTileKey;
    if (rawTown == null || rawTown.isEmpty) {
      final msg =
          'capital reassignment: missing townTileKey for province $newProvinceId player ${player.id}';
      final err = StateError(msg);
      _log.e(msg, error: err, stackTrace: StackTrace.current);
      throw CapitalReassignmentFatalError(msg, err);
    }

    late final CapitalTile tile;
    try {
      tile = CapitalTile.parseTownTileKey(rawTown, newProvinceId);
    } catch (e, st) {
      final msg =
          'capital reassignment: invalid townTileKey for province $newProvinceId player ${player.id} raw="$rawTown"';
      _log.e(msg, error: e, stackTrace: st);
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
      _log.i(
        'player ${player.id} capital reassigned to $newProvinceId ($newCapKey) after loss',
      );
    } catch (e, st) {
      final msg =
          'capital reassignment: failed to apply new capital for ${player.id}';
      _log.e(msg, error: e, stackTrace: st);
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
    final parts = key.split('|');
    if (parts.length >= 3) {
      final provinceId = '${parts[0]}|${parts[1]}';
      portsByProvince.putIfAbsent(provinceId, () => []).add(key);
    }
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

    final newOldWorld = transferRegion(game.worldState.oldWorld);
    final newNewWorld = transferRegion(game.worldState.newWorld);

    final remainingFleets = game.worldState.fleets
        .where((f) => f.ownerId != playerId)
        .toList();

    game = game
        .copyWith(
          worldState: game.worldState.copyWith(
            oldWorld: newOldWorld,
            newWorld: newNewWorld,
            fleets: remainingFleets,
          ),
        )
        .mapPlayers(
          (p) => p.id == playerId
              ? p.copyWith(capitalProvinceId: null, capitalTile: null)
              : p,
        );
  }

  return game;
}
