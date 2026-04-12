import 'package:colonizethis_data/colonizethis_data.dart';

/// Orthogonal scan order: North, East, South, West.
/// SPEC/ui/town-port-icons.md, GitHub #1761.
const kPortIconSeaNeighborDeltas = <(int dx, int dy)>[
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];

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
  final parts = portTileKey.split('|');
  if (parts.length < 4) {
    throw PortDrawableSeaCellException(
      'Invalid port tile key (expected region|province|x|y): "$portTileKey"'
      '${_portPlacementContextSuffix(contextLabel)}',
    );
  }
  final px = int.tryParse(parts[parts.length - 2]);
  final py = int.tryParse(parts[parts.length - 1]);
  if (px == null || py == null) {
    throw PortDrawableSeaCellException(
      'Port tile key has non-integer x|y: "$portTileKey"'
      '${_portPlacementContextSuffix(contextLabel)}',
    );
  }
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
