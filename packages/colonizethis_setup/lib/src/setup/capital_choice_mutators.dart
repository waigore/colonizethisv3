import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'setup_exceptions.dart';
import 'setup_road_wiring.dart';

/// Updates WorldState with capital port and road for the given capital tile.
/// Shared by [setCapital] and [setCapitalForMinorNation] / [setCapitalForTribe].
WorldState applyCapitalPortAndRoad(
  WorldState worldState,
  String provinceId,
  CapitalTile tile,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
) {
  final regionId = tile.regionId;
  final map = tileMapByRegion[regionId];
  if (map == null) {
    throw SetupTopologyDataException(
      code: 'missing_region_tile_map',
      details: 'No tile map for region $regionId',
    );
  }

  final capitalKey = tile.toTileKey();
  return applySeaboardPortAndRoadWiring(
    worldState: worldState,
    provinceId: provinceId,
    inlandTileKey: capitalKey,
    inlandX: tile.x,
    inlandY: tile.y,
    regionId: regionId,
    topology: topology,
    map: map,
    pathRoadLevel: 1,
    missingCoastalPolicy: SeaboardMissingCoastalPolicy.throwException,
    existingPortPolicy: SeaboardExistingPortPolicy.overwrite,
    pathMissingPolicy: SeaboardPathMissingPolicy.useStartOnly,
    requireSeaBoundProvince: false,
    throwIfNoSeaZones: true,
  );
}

/// Sets [playerId]'s capital to [provinceId] at [tile]. Validates province is
/// sea-bound; auto-builds port and road. Returns updated Game; caller persists.
Game setCapital({
  required Game game,
  required String playerId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  if (!isProvinceSeaBound(topology, ProvinceId.localIdFrom(provinceId))) {
    throw NoSeaBoundCapitalProvinceException(
      details: 'Province $provinceId is not sea-bound',
    );
  }
  if (tile.provinceId != provinceId) {
    throw CapitalTileMismatchException(
      details:
          'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }

  var worldState = applyCapitalPortAndRoad(
    game.worldState,
    provinceId,
    tile,
    topology,
    tileMapByRegion,
  );
  worldState = applyGreatPowerCapitalProvinceTownDevelopment(
    worldState,
    tile.regionId,
    provinceId,
  );

  return game.withWorldState(worldState).mapPlayers((p) {
    if (p.id != playerId) return p;
    return p.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  });
}

/// Sets a Minor Nation's capital. Port/road applied only when province is sea-bound.
Game setCapitalForMinorNation({
  required Game game,
  required String minorId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  return setCapitalForMinorOrTribe(
    game: game,
    ownerId: minorId,
    provinceId: provinceId,
    tile: tile,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    forTribe: false,
  );
}

/// Sets a Tribe's capital. Port/road applied only when province is sea-bound.
Game setCapitalForTribe({
  required Game game,
  required String tribeId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  return setCapitalForMinorOrTribe(
    game: game,
    ownerId: tribeId,
    provinceId: provinceId,
    tile: tile,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    forTribe: true,
  );
}

/// Shared mutator for inland-allowed minor/tribe capitals (single copyWith owner).
Game setCapitalForMinorOrTribe({
  required Game game,
  required String ownerId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required bool forTribe,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalTileMismatchException(
      details:
          'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }

  final worldState =
      isProvinceSeaBound(topology, ProvinceId.localIdFrom(provinceId))
      ? applyCapitalPortAndRoad(
          game.worldState,
          provinceId,
          tile,
          topology,
          tileMapByRegion,
        )
      : game.worldState;

  if (forTribe) {
    final updatedTribes = game.tribes.map((t) {
      if (t.id != ownerId) return t;
      return t.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
    }).toList();
    return game.copyWith(worldState: worldState, tribes: updatedTribes);
  }

  final updatedMinors = game.minorNations.map((m) {
    if (m.id != ownerId) return m;
    return m.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  }).toList();
  return game.copyWith(worldState: worldState, minorNations: updatedMinors);
}
