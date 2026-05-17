import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'map_pipe_string_util.dart';
import 'tile_key_util.dart';
import 'tile_map_directions.dart';

/// Orthogonal scan order: North, East, South, West.
/// SPEC/ui/town-port-icons.md, GitHub #1761.
const kPortIconSeaNeighborDeltas = kTileMapDirections4;

/// Raised when [computePortDrawableSeaCellForMap] cannot resolve a sea cell.
/// SPEC/ui/town-port-icons.md, GitHub #1761.
class PortDrawableSeaCellException implements Exception {
  PortDrawableSeaCellException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resolves drawable grid coordinates for the port / in-port fleet marker.
///
/// Uses the **authoritative port land tile** from `portsByProvinceSeaboard`
/// (tile key `regionId|localProvinceId|x|y`):
///
/// * If that cell's map id is in [seaZoneIds], returns that cell.
/// * Otherwise scans orthogonal neighbors of **that port tile** in N→E→S→W
///   order and returns the first cell whose id is in [seaZoneIds].
/// * If none qualify, throws [PortDrawableSeaCellException] (no land fallback).
///
/// The returned cell is always validated to be a sea zone cell.
/// GitHub #1761, SPEC/ui/town-port-icons.md.
({int x, int y}) computePortDrawableSeaCellForMap({
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required String portTileKey,
  String? contextLabel,
}) {
  final parsed = tryParseMapTileKeySuffixXY(portTileKey);
  if (parsed == null) {
    throw PortDrawableSeaCellException(
      'Invalid port tile key (expected region|province|x|y): "$portTileKey"'
      '${_portPlacementContextSuffix(contextLabel)}',
    );
  }
  final px = parsed.x;
  final py = parsed.y;
  if (px < 0 || py < 0 || px >= tileMap.width || py >= tileMap.height) {
    throw PortDrawableSeaCellException(
      'Port tile ($px,$py) is outside tile map '
      '${tileMap.width}×${tileMap.height} for "$portTileKey"'
      '${_portPlacementContextSuffix(contextLabel)}',
    );
  }

  bool isSea(int x, int y) => seaZoneIds.contains(tileMap.cell(x, y));

  if (isSea(px, py)) {
    return (x: px, y: py);
  }

  for (final d in kPortIconSeaNeighborDeltas) {
    final nx = px + d.$1;
    final ny = py + d.$2;
    if (nx < 0 || ny < 0 || nx >= tileMap.width || ny >= tileMap.height) {
      continue;
    }
    if (isSea(nx, ny)) {
      return (x: nx, y: ny);
    }
  }

  throw PortDrawableSeaCellException(
    'No orthogonal sea cell in seaZoneIds from port tile ($px,$py) for '
    '"$portTileKey"${_portPlacementContextSuffix(contextLabel)}',
  );
}

String _portPlacementContextSuffix(String? contextLabel) {
  if (contextLabel == null || contextLabel.isEmpty) {
    return '';
  }
  return ' ($contextLabel)';
}

/// Local province id from a `portsByProvinceSeaboard` **key** for [regionId].
/// SPEC/ui/town-port-icons.md, GitHub #1770.
String? localProvinceIdFromPortsSeaboardKey(
  String seaboardKey,
  String regionId,
) => mapPipeLocalProvinceIdFromPortsSeaboardKey(seaboardKey, regionId);

/// Authoritative **land** port tile key from [Game.worldState.portsByProvinceSeaboard]
/// for [localProvinceId] in [regionId]. Null when no entry matches.
String? portLandTileKeyForProvinceInRegion(
  Game game,
  String regionId,
  String localProvinceId,
) {
  for (final e in game.worldState.portsByProvinceSeaboard.entries) {
    final fromKey = localProvinceIdFromPortsSeaboardKey(e.key, regionId);
    if (fromKey == localProvinceId) {
      return e.value;
    }
  }
  for (final e in game.worldState.portsByProvinceSeaboard.entries) {
    final parsed = tryParseMapTileKey(e.value);
    if (parsed != null &&
        parsed.regionId == regionId &&
        parsed.localId == localProvinceId) {
      return e.value;
    }
  }
  return null;
}

/// Full map tile key for the drawable harbor **sea** cell (port sprite,
/// `FleetTileMarkerView` in port, dock-move preview). Format
/// `regionId|seaCellId|x|y` where `seaCellId` is [TileMapResult.cell] at the
/// resolved coordinates.
///
/// Returns null when there is no matching `portsByProvinceSeaboard` entry.
/// Throws [PortDrawableSeaCellException] when an entry exists but no valid sea
/// drawable can be resolved (same as [computePortDrawableSeaCellForMap]).
/// GitHub #1770, SPEC/ui/town-port-icons.md.
String? harborDrawableSeaTileKeyForPortProvince({
  required Game game,
  required String regionId,
  required String localProvinceId,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  String? contextLabel,
}) {
  final portTileKey = portLandTileKeyForProvinceInRegion(
    game,
    regionId,
    localProvinceId,
  );
  if (portTileKey == null) {
    return null;
  }
  final placed = computePortDrawableSeaCellForMap(
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    portTileKey: portTileKey,
    contextLabel:
        contextLabel ??
        'harbor drawable region=$regionId province=$localProvinceId',
  );
  final cx = placed.x;
  final cy = placed.y;
  final regionCellId = tileMap.cell(cx, cy);
  return '$regionId|$regionCellId|$cx|$cy';
}
