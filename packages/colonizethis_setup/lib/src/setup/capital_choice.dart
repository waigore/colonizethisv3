import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'capital_choice_capital_tile_scan.dart';
import 'setup_exceptions.dart';
import 'setup_road_wiring.dart';

export 'package:colonizethis_world/colonizethis_world.dart'
    show
        applyGreatPowerCapitalProvinceTownDevelopment,
        pickCapitalProvinceIdForReassignment,
        setCapitalForMinorReassignment,
        setCapitalForReassignment,
        setCapitalForTribeReassignment;

export 'package:colonizethis_data/colonizethis_data.dart'
    show isProvinceSeaBound;

export 'capital_choice_classify.dart';

/// Capital-choice phase stub. SPEC/game/capital-choice-phase.
///
/// setCapital validates province is sea-bound, sets player capital, and
/// auto-builds port (on capital if coastal, else nearest coastal tile) and road.

/// Picks a capital province and tile for a faction. SPEC/game/capital-choice-phase#auto-choice-game-setup.
/// [ownedProvinceIds] and [regionId] come from assignment; [topology] and [tileMap] are for that region.
/// Returns (provinceId, CapitalTile). When [requireSeaBound] is true (GPs), throws if no sea-bound province.
/// When [requireSeaBound] is false (minors/tribes), falls back to first owned province if none are sea-bound.
(String provinceId, CapitalTile tile) pickCapitalForFaction(
  List<String> ownedProvinceIds,
  String regionId,
  MapTopology topology,
  TileMapResult tileMap, {
  bool requireSeaBound = true,
}) {
  final provinceId = capitalProvinceIdFromSeaBoundOrFallback(
    ownedProvinceIds,
    topology,
    requireSeaBound: requireSeaBound,
  );

  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  // Tile choice with border-avoidance heuristic:
  // Class A: coastal tiles not adjacent to other provinces.
  // Class B: interior tiles not adjacent to other provinces.
  // Class C: remaining tiles.
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();

  final c = scanCapitalTileCandidates(
    tileMap: tileMap,
    topology: topology,
    localProvinceId: localProvinceId,
    provinceIds: provinceIds,
  );

  final (x, y) = capitalTileXYFromScan(
    requireSeaBound: requireSeaBound,
    provinceId: provinceId,
    regionId: regionId,
    classAx: c.classAx,
    classAy: c.classAy,
    classAPlainsX: c.classAPlainsX,
    classAPlainsY: c.classAPlainsY,
    classBx: c.classBx,
    classBy: c.classBy,
    classBPlainsX: c.classBPlainsX,
    classBPlainsY: c.classBPlainsY,
    classCx: c.classCx,
    classCy: c.classCy,
    classCPlainsX: c.classCPlainsX,
    classCPlainsY: c.classCPlainsY,
    classCCoastalX: c.classCCoastalX,
    classCCoastalY: c.classCCoastalY,
    classCCoastalPlainsX: c.classCCoastalPlainsX,
    classCCoastalPlainsY: c.classCCoastalPlainsY,
  );
  final tile = CapitalTile(
    regionId: regionId,
    provinceId: provinceId,
    x: x,
    y: y,
  );
  return (provinceId, tile);
}

/// Updates WorldState with capital port and road for the given capital tile. Shared by setCapital and setCapitalForMinor/Tribe.
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

/// Sets [playerId]'s capital to [provinceId] at [tile]. Validates province is sea-bound;
/// auto-builds port (on capital tile if adjacent to sea, else nearest coastal tile in province)
/// and road along shortest path from port to capital. Returns updated Game; caller persists.
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
/// SPEC/game/capital-choice-phase: minors may have inland capitals.
Game setCapitalForMinorNation({
  required Game game,
  required String minorId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
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

  final updatedMinors = game.minorNations.map((m) {
    if (m.id != minorId) return m;
    return m.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  }).toList();

  // Atomic multi-field mutation (worldState + minorNations); kept as raw
  // copyWith per Issue #2836 AC 6 single-field-only helper scope.
  return game.copyWith(worldState: worldState, minorNations: updatedMinors);
}

/// Sets a Tribe's capital. Port/road applied only when province is sea-bound.
/// SPEC/game/capital-choice-phase: tribes may have inland capitals.
Game setCapitalForTribe({
  required Game game,
  required String tribeId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
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

  final updatedTribes = game.tribes.map((t) {
    if (t.id != tribeId) return t;
    return t.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  }).toList();

  // Atomic multi-field mutation (worldState + tribes); kept as raw copyWith
  // per Issue #2836 AC 6 single-field-only helper scope.
  return game.copyWith(worldState: worldState, tribes: updatedTribes);
}
