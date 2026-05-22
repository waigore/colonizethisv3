import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import '../world/player_state_pipeline.dart';
import 'setup_exceptions.dart';

export 'package:colonizethis_data/colonizethis_data.dart'
    show isProvinceSeaBound;

part 'capital_choice_capital_tile_scan.dart';

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

/// New capital **province** id for runtime reassignment after combat (not init capital choice).
/// [ownedProvinceIds] are full `regionId|localId`. Prefers **seaboard** provinces; if none, uses inland.
/// Deterministic: ascending sort by full id, first in the preferred set.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
String pickCapitalProvinceIdForReassignment(
  List<String> ownedProvinceIds,
  MapTopology topology,
) {
  if (ownedProvinceIds.isEmpty) {
    throw SetupConfigConstraintException(
      code: 'capital_reassignment_requires_owned_provinces',
      details: 'ownedProvinceIds must be non-empty',
    );
  }
  final sorted = List<String>.from(ownedProvinceIds)..sort();
  final seaBound = sorted
      .where((id) => isProvinceSeaBound(topology, ProvinceId.localIdFrom(id)))
      .toList();
  if (seaBound.isNotEmpty) return seaBound.first;
  return sorted.first;
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

/// SPEC/game/capital-and-connectivity § Capital province town development (Great Powers).
/// [capitalProvinceId] may be full (`regionId|localId`) or local only; match by local id
/// within [regionId].
WorldState applyGreatPowerCapitalProvinceTownDevelopment(
  WorldState worldState,
  String regionId,
  String capitalProvinceId,
) {
  final localTarget = ProvinceId.isPrefixed(capitalProvinceId)
      ? ProvinceId.localIdFrom(capitalProvinceId)
      : capitalProvinceId;
  return worldState.updateRegionById(
    regionId,
    (region) => RegionData(
      provinces: region.provinces
          .map(
            (p) => ProvinceId.localIdFrom(p.id) == localTarget
                ? p.copyWith(townDevelopmentLevel: 4)
                : p,
          )
          .toList(),
      units: region.units,
    ),
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

  return game.copyWith(worldState: worldState).mapPlayers((p) {
    if (p.id != playerId) return p;
    return p.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  });
}

/// Sets [playerId]'s capital after runtime reassignment (combat). Updates **only** player
/// `capitalProvinceId` and `capitalTile`; does not place ports, roads, or change province
/// `townTileKey`. SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game setCapitalForReassignment({
  required Game game,
  required String playerId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalTileMismatchException(
      details:
          'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  return game.mapPlayers((p) {
    if (p.id != playerId) return p;
    return p.copyWith(capitalProvinceId: provinceId, capitalTile: tile);
  });
}

/// Sets [minorId]'s capital after runtime reassignment (combat / debug flip). Updates
/// **only** the Minor Nation's `capitalProvinceId` and `capitalTile`; does not place
/// ports/roads, does not change any province's `townTileKey` or `townDevelopmentLevel`.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game setCapitalForMinorReassignment({
  required Game game,
  required String minorId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalTileMismatchException(
      details:
          'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  final updatedMinors = game.minorNations
      .map(
        (m) => m.id != minorId
            ? m
            : m.copyWith(capitalProvinceId: provinceId, capitalTile: tile),
      )
      .toList();
  return game.copyWith(minorNations: updatedMinors);
}

/// Sets [tribeId]'s capital after runtime reassignment (combat / debug flip). Updates
/// **only** the Tribe's `capitalProvinceId` and `capitalTile`; does not place ports/roads,
/// does not change any province's `townTileKey` or `townDevelopmentLevel`.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game setCapitalForTribeReassignment({
  required Game game,
  required String tribeId,
  required String provinceId,
  required CapitalTile tile,
}) {
  if (tile.provinceId != provinceId) {
    throw CapitalTileMismatchException(
      details:
          'Capital tile province ${tile.provinceId} does not match $provinceId',
    );
  }
  final updatedTribes = game.tribes
      .map(
        (t) => t.id != tribeId
            ? t
            : t.copyWith(capitalProvinceId: provinceId, capitalTile: tile),
      )
      .toList();
  return game.copyWith(tribes: updatedTribes);
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

TopologyNode? _topologyNodeById(MapTopology topology, String id) {
  for (final n in topology.nodes) {
    if (n.id == id) return n;
  }
  return null;
}

Set<String> _seaZonesAdjacentToProvince(
  MapTopology topology,
  String provinceId,
) {
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != provinceId && edge.id2 != provinceId) continue;
    final other = edge.id1 == provinceId ? edge.id2 : edge.id1;
    final node = _topologyNodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) out.add(other);
  }
  return out;
}

bool _isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIds.contains(cellId)) return true;
  }
  return false;
}

bool _isTileAdjacentToOtherProvince(
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIds,
  String provinceId,
) {
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIds.contains(cellId)) continue;
    if (cellId != provinceId) return true;
  }
  return false;
}

(int, int)? _nearestCoastalTileInProvinceForSeaZone(
  TileMapResult map,
  String provinceId,
  int fromX,
  int fromY,
  MapTopology topology,
  String seaZoneId,
) {
  int? bestDist;
  int? bestX;
  int? bestY;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != provinceId) continue;
      if (!_isTileAdjacentToSeaZone(x, y, map, topology, seaZoneId)) continue;
      final dist = (x - fromX).abs() + (y - fromY).abs();
      if (bestDist == null || dist < bestDist) {
        bestDist = dist;
        bestX = x;
        bestY = y;
      }
    }
  }
  if (bestX == null || bestY == null) return null;
  return (bestX, bestY);
}

bool _isTileAdjacentToSeaZone(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
  String seaZoneId,
) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  final seaZoneLocal = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (provinceIds.contains(cellId)) continue;
    if (cellId == seaZoneId || cellId == seaZoneLocal) return true;
  }
  return false;
}

/// Shortest path on province tiles only (BFS). Returns ordered list (start .. end) inclusive.
/// Used for road placement from port to capital. SPEC/game/capital-and-connectivity § Capital Setup.
List<(int, int)> _shortestPathOnProvinceTiles(
  TileMapResult map,
  String localProvinceId,
  int fromX,
  int fromY,
  int toX,
  int toY,
) {
  if (fromX == toX && fromY == toY) return [(fromX, fromY)];
  final w = map.width;
  final h = map.height;
  final visited = <String>{};
  final parent = <String, (int, int)>{};
  final startKey = '$fromX|$fromY';
  visited.add(startKey);
  final queue = Queue<(int, int)>()..add((fromX, fromY));
  while (queue.isNotEmpty) {
    final (cx, cy) = queue.removeFirst();
    if (cx == toX && cy == toY) {
      final path = <(int, int)>[];
      var (px, py) = (toX, toY);
      while (true) {
        path.insert(0, (px, py));
        final key = '$px|$py';
        final p = parent[key];
        if (p == null) break;
        px = p.$1;
        py = p.$2;
      }
      return path;
    }
    for (final d in kGridNeighborsCardinal4) {
      final nx = cx + d.$1;
      final ny = cy + d.$2;
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
      if (map.cell(nx, ny) != localProvinceId) continue;
      final nkey = '$nx|$ny';
      if (visited.contains(nkey)) continue;
      visited.add(nkey);
      parent[nkey] = (cx, cy);
      queue.add((nx, ny));
    }
  }
  return [(fromX, fromY)];
}
