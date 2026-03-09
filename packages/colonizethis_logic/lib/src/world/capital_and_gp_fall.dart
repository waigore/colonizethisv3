import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../setup/capital_choice.dart';
import '../world/province_lookup.dart';

final Logger _log = Logger();

Game applyCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  Game game = state;
  for (final player in state.players) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null || player.capitalTile == null) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final regionTopology = topologyByRegion?[regionId] ?? topology;
    final region = regionId == kRegionOldWorld
        ? state.worldState.oldWorld
        : state.worldState.newWorld;
    final province =
        region.provinces.where((p) => p.id == capProvinceId).firstOrNull;
    if (province == null) continue;
    if (province.ownerId == player.id) continue;

    final ownedInRegion = region.provinces
        .where((p) => p.ownerId == player.id)
        .map((p) => p.id)
        .toList();
    if (ownedInRegion.isEmpty) {
      final updatedPlayers = game.players.map((p) {
        if (p.id != player.id) return p;
        return p.copyWith(capitalProvinceId: null, capitalTile: null);
      }).toList();
      game = game.copyWith(players: updatedPlayers);
      _log.i(
          'logic: player ${player.id} lost capital and has no provinces in $regionId; capital cleared');
      continue;
    }
    final tileMap = tileMapByRegion[regionId];
    if (tileMap == null) continue;
    try {
      final (newProvinceId, tile) = pickCapitalForFaction(
        ownedInRegion,
        regionId,
        regionTopology,
        tileMap,
        requireSeaBound: false,
      );
      game = setCapitalForReassignment(
        game: game,
        playerId: player.id,
        provinceId: newProvinceId,
        tile: tile,
        topology: regionTopology,
        tileMapByRegion: tileMapByRegion,
      );
      _log.i(
          'logic: player ${player.id} capital reassigned to $newProvinceId after loss');
    } catch (e, st) {
      _log.w('logic: capital reassignment failed for ${player.id}',
          error: e, stackTrace: st);
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
    for (final p in game.worldState.oldWorld.provinces) p.id: p.ownerId,
    for (final p in game.worldState.newWorld.provinces) p.id: p.ownerId,
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
          .map((p) =>
              p.ownerId == playerId ? p.copyWith(ownerId: conquerorId) : p)
          .toList();
      final remainingUnits =
          region.units.where((u) => u.ownerId != playerId).toList();
      return RegionData(
        provinces: updatedProvinces,
        units: remainingUnits,
      );
    }

    final newOldWorld = transferRegion(game.worldState.oldWorld);
    final newNewWorld = transferRegion(game.worldState.newWorld);

    final remainingFleets = game.worldState.fleets
        .where((f) => f.ownerId != playerId)
        .toList();

    game = game.copyWith(
      worldState: game.worldState.copyWith(
        oldWorld: newOldWorld,
        newWorld: newNewWorld,
        fleets: remainingFleets,
      ),
      players: game.players
          .map((p) => p.id == playerId
              ? p.copyWith(capitalProvinceId: null, capitalTile: null)
              : p)
          .toList(),
    );
  }

  return game;
}

