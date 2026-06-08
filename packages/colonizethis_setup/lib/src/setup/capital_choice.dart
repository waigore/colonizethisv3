import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world_constants.dart';
import 'package:colonizethis_world/src/world/capital_reassignment.dart';
import 'package:colonizethis_world/src/world/game_world_mutations.dart';
import 'package:colonizethis_world/src/world/player_state_pipeline.dart';
import 'setup_exceptions.dart';

export 'package:colonizethis_world/src/world/capital_reassignment.dart'
    show
        applyGreatPowerCapitalProvinceTownDevelopment,
        pickCapitalProvinceIdForReassignment,
        setCapitalForMinorReassignment,
        setCapitalForReassignment,
        setCapitalForTribeReassignment;

export 'package:colonizethis_data/colonizethis_data.dart'
    show isProvinceSeaBound;

part 'capital_choice_capital_tile_scan.dart';
part 'capital_choice_port_road_geometry.dart';

/// Capital-choice phase stub. SPEC/game/capital-choice-phase.
///
/// setCapital validates province is sea-bound, sets player capital, and
/// auto-builds port (on capital if coastal, else nearest coastal tile) and road.

/// Capital tile class per SPEC/game/capital-choice-phase:
/// - A: coastal and not adjacent to another province
/// - B: interior and not adjacent to another province
/// - C: all remaining tiles
enum CapitalTileClass { a, b, c }

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
  final provinceId = _capitalProvinceIdFromSeaBoundOrFallback(
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

  final c = _scanCapitalTileCandidates(
    tileMap: tileMap,
    topology: topology,
    localProvinceId: localProvinceId,
    provinceIds: provinceIds,
  );
  final classAx = c.classAx;
  final classAy = c.classAy;
  final classBx = c.classBx;
  final classBy = c.classBy;
  final classCx = c.classCx;
  final classCy = c.classCy;
  final classCCoastalX = c.classCCoastalX;
  final classCCoastalY = c.classCCoastalY;

  final (x, y) = _capitalTileXYFromScan(
    requireSeaBound: requireSeaBound,
    provinceId: provinceId,
    regionId: regionId,
    classAx: classAx,
    classAy: classAy,
    classBx: classBx,
    classBy: classBy,
    classCx: classCx,
    classCy: classCy,
    classCCoastalX: classCCoastalX,
    classCCoastalY: classCCoastalY,
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
  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  var tileState = worldState.tileState;
  var ports = Map<String, String>.from(worldState.portsByProvinceSeaboard);

  final capitalKey = tile.toTileKey();
  final seaZoneIds = _seaZonesAdjacentToProvince(
    topology,
    localProvinceId,
  ).toList()..sort();
  if (seaZoneIds.isEmpty) {
    throw SetupTopologyDataException(
      code: 'province_has_no_sea_zone',
      details: 'Province $provinceId has no sea zone in topology',
    );
  }

  for (final seaZoneId in seaZoneIds) {
    final portKeyProvSea = '$provinceId|$seaZoneId';
    final capitalTouchesSeaZone = _isTileAdjacentToSeaZone(
      tile.x,
      tile.y,
      map,
      topology,
      seaZoneId,
    );
    if (capitalTouchesSeaZone) {
      tileState = _setRoadLevelMax(tileState, capitalKey, 4);
      ports[portKeyProvSea] = capitalKey;
      continue;
    }

    final coastal = _nearestCoastalTileInProvinceForSeaZone(
      map,
      localProvinceId,
      tile.x,
      tile.y,
      topology,
      seaZoneId,
    );
    if (coastal == null) {
      throw SetupTopologyDataException(
        code: 'seaboard_port_tile_not_found',
        details:
            'No coastal tile in province $provinceId for sea zone $seaZoneId',
      );
    }
    final portKey = CapitalTile.tileKey(
      regionId,
      provinceId,
      coastal.$1,
      coastal.$2,
    );
    tileState = _setRoadLevelMax(tileState, capitalKey, 1);
    tileState = _setRoadLevelMax(tileState, portKey, 4);
    ports[portKeyProvSea] = portKey;
    // Shortest path from seaboard-specific port to capital on province tiles.
    final path = _shortestPathOnProvinceTiles(
      map,
      localProvinceId,
      coastal.$1,
      coastal.$2,
      tile.x,
      tile.y,
    );
    for (final p in path) {
      final key = CapitalTile.tileKey(regionId, provinceId, p.$1, p.$2);
      if (key == portKey) continue;
      tileState = _setRoadLevelMax(tileState, key, 1);
    }
  }

  return worldState.copyWith(
    tileState: tileState,
    portsByProvinceSeaboard: ports,
  );
}

TileMapState _setRoadLevelMax(
  TileMapState tileState,
  String tileKey,
  int level,
) {
  final current = tileState.roadLevel(tileKey);
  if (current >= level) return tileState;
  return tileState.setRoadLevel(tileKey, level);
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

/// Classifies a province tile according to capital-choice class A/B/C.
CapitalTileClass classifyCapitalTile({
  required int x,
  required int y,
  required TileMapResult tileMap,
  required MapTopology topology,
  required String localProvinceId,
  Set<String>? provinceIds,
}) {
  final knownProvinceIds =
      provinceIds ??
      topology.nodes
          .where((n) => n.type == TopologyNodeType.province)
          .map((n) => n.id)
          .toSet();
  final coastal = _isTileAdjacentToSea(x, y, tileMap, topology);
  final adjacentOtherProvince = _isTileAdjacentToOtherProvince(
    x,
    y,
    tileMap,
    knownProvinceIds,
    localProvinceId,
  );
  if (coastal && !adjacentOtherProvince) return CapitalTileClass.a;
  if (!coastal && !adjacentOtherProvince) return CapitalTileClass.b;
  return CapitalTileClass.c;
}
