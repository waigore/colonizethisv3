import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Capital-choice phase stub. SPEC/game/capital-choice-phase.
///
/// setCapital validates province is sea-bound, sets player capital, and
/// auto-builds port (on capital if coastal, else nearest coastal tile) and road.

/// Returns true if [provinceId] has at least one P–S edge in [topology].
bool isProvinceSeaBound(MapTopology topology, String provinceId) {
  for (final edge in topology.edges) {
    if (edge.id1 != provinceId && edge.id2 != provinceId) continue;
    final other = edge.id1 == provinceId ? edge.id2 : edge.id1;
    final node = _nodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) return true;
  }
  return false;
}

TopologyNode? _nodeById(MapTopology topology, String id) {
  for (final n in topology.nodes) {
    if (n.id == id) return n;
  }
  return null;
}

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
  // Topology/tileMap use local ids; ownedProvinceIds are full (regionId|localId).
  final seaBound = ownedProvinceIds
      .where((id) => isProvinceSeaBound(topology, ProvinceId.localIdFrom(id)))
      .toList()
    ..sort();
  final provinceId = seaBound.isNotEmpty
      ? seaBound.first
      : (requireSeaBound
          ? (throw ArgumentError(
              'No sea-bound province among $ownedProvinceIds; setup must assign at least one sea-bound per faction',
            ))
          : (List<String>.from(ownedProvinceIds)..sort()).first);

  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  // Tile choice with border-avoidance heuristic:
  // Class A: coastal tiles not adjacent to other provinces.
  // Class B: interior tiles not adjacent to other provinces.
  // Class C: remaining tiles.
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();

  int? classAx;
  int? classAy;
  int? classBx;
  int? classBy;
  int? classCx;
  int? classCy;

  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      if (tileMap.cell(x, y) != localProvinceId) continue;
      final coastal = _isTileAdjacentToSea(x, y, tileMap, topology);
      final adjacentOtherProvince =
          _isTileAdjacentToOtherProvince(x, y, tileMap, provinceIds, localProvinceId);

      if (coastal && !adjacentOtherProvince) {
        if (classAx == null) {
          classAx = x;
          classAy = y;
        }
      } else if (!coastal && !adjacentOtherProvince) {
        if (classBx == null) {
          classBx = x;
          classBy = y;
        }
      } else {
        if (classCx == null) {
          classCx = x;
          classCy = y;
        }
      }
    }
  }

  int? x;
  int? y;

  if (classAx != null) {
    x = classAx;
    y = classAy;
  } else if (classBx != null) {
    x = classBx;
    y = classBy;
  } else if (classCx != null) {
    x = classCx;
    y = classCy;
  }

  if (x == null || y == null) {
    throw ArgumentError('No tile found in province $provinceId in region $regionId');
  }
  final tile = CapitalTile(regionId: regionId, provinceId: provinceId, x: x, y: y);
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
  if (map == null) throw ArgumentError('No tile map for region $regionId');
  final localProvinceId = ProvinceId.localIdFrom(provinceId);

  var tileState = worldState.tileState;
  var ports = Map<String, String>.from(worldState.portsByProvinceSeaboard);

  final capitalKey = tile.toTileKey();
  final seaZoneIds = _seaZonesAdjacentToProvince(topology, localProvinceId);
  if (seaZoneIds.isEmpty) throw ArgumentError('Province $provinceId has no sea zone in topology');

  final seaZoneId = seaZoneIds.first;
  final portKeyProvSea = '$provinceId|$seaZoneId';

  final isCapitalCoastal = _isTileAdjacentToSea(tile.x, tile.y, map, topology);
  if (isCapitalCoastal) {
    tileState = tileState.setRoadLevel(capitalKey, 4);
    ports[portKeyProvSea] = capitalKey;
  } else {
    final coastal = _nearestCoastalTileInProvince(
      map,
      localProvinceId,
      tile.x,
      tile.y,
      topology,
    );
    if (coastal == null) throw ArgumentError('No coastal tile in province $provinceId');
    final portKey = CapitalTile.tileKey(regionId, provinceId, coastal.$1, coastal.$2);
    tileState = tileState.setRoadLevel(capitalKey, 1);
    tileState = tileState.setRoadLevel(portKey, 4);
    ports[portKeyProvSea] = portKey;
  }

  return worldState.copyWith(
    tileState: tileState,
    portsByProvinceSeaboard: ports,
  );
}

/// Sets [playerId]'s capital to [provinceId] at [tile]. Validates province is sea-bound;
/// auto-builds port (on capital tile if adjacent to sea, else nearest coastal tile in province)
/// and road (stub: road on capital and port tile). Returns updated Game; caller persists.
Game setCapital({
  required Game game,
  required String playerId,
  required String provinceId,
  required CapitalTile tile,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  if (!isProvinceSeaBound(topology, ProvinceId.localIdFrom(provinceId))) {
    throw ArgumentError('Province $provinceId is not sea-bound');
  }
  if (tile.provinceId != provinceId) {
    throw ArgumentError('Capital tile province ${tile.provinceId} does not match $provinceId');
  }

  final worldState = applyCapitalPortAndRoad(
    game.worldState,
    provinceId,
    tile,
    topology,
    tileMapByRegion,
  );

  final updatedPlayers = game.players.map((p) {
    if (p.id != playerId) return p;
    return p.copyWith(
      capitalProvinceId: provinceId,
      capitalTile: tile,
    );
  }).toList();

  return game.copyWith(
    worldState: worldState,
    players: updatedPlayers,
  );
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
    throw ArgumentError('Capital tile province ${tile.provinceId} does not match $provinceId');
  }

  final worldState = isProvinceSeaBound(topology, ProvinceId.localIdFrom(provinceId))
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

  return game.copyWith(
    worldState: worldState,
    minorNations: updatedMinors,
  );
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
    throw ArgumentError('Capital tile province ${tile.provinceId} does not match $provinceId');
  }

  final worldState = isProvinceSeaBound(topology, ProvinceId.localIdFrom(provinceId))
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

  return game.copyWith(
    worldState: worldState,
    tribes: updatedTribes,
  );
}

Set<String> _seaZonesAdjacentToProvince(MapTopology topology, String provinceId) {
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != provinceId && edge.id2 != provinceId) continue;
    final other = edge.id1 == provinceId ? edge.id2 : edge.id1;
    final node = _nodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) out.add(other);
  }
  return out;
}

bool _isTileAdjacentToSea(int x, int y, TileMapResult map, MapTopology topology) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  final w = map.width;
  final h = map.height;
  for (final d in [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
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
  for (final d in [(0, -1), (1, 0), (0, 1), (-1, 0)]) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIds.contains(cellId)) continue;
    if (cellId != provinceId) return true;
  }
  return false;
}

(int, int)? _nearestCoastalTileInProvince(
  TileMapResult map,
  String provinceId,
  int fromX,
  int fromY,
  MapTopology topology,
) {
  int? bestDist;
  int? bestX;
  int? bestY;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != provinceId) continue;
      if (!_isTileAdjacentToSea(x, y, map, topology)) continue;
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
