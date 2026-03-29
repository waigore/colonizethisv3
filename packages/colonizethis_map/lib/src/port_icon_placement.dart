import 'package:colonizethis_data/colonizethis_data.dart';

/// Orthogonal scan order: North, East, South, West. Spec: SPEC/ui/town-port-icons.md.
const kPortIconSeaNeighborDeltas = <(int dx, int dy)>[
  (0, -1),
  (1, 0),
  (0, 1),
  (-1, 0),
];

/// Resolves drawable grid coordinates for the port icon.
///
/// When the port tile is not shared with the town or capital tile, returns the
/// port tile. When shared, returns the first orthogonal sea cell adjacent to
/// the **town** tile in N→E→S→W order; if none, returns the port tile (fallback
/// stack). GitHub #1361, SPEC/ui/town-port-icons.md.
({int x, int y}) computePortIconCellForMap({
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required int townX,
  required int townY,
  required String townTileKey,
  required String? capitalTileKey,
  required String portTileKey,
}) {
  final portParts = portTileKey.split('|');
  if (portParts.length < 4) {
    return (x: townX, y: townY);
  }
  final px = int.tryParse(portParts[2]);
  final py = int.tryParse(portParts[3]);
  if (px == null || py == null) {
    return (x: townX, y: townY);
  }

  final coLocatedWithTown = portTileKey == townTileKey;
  final coLocatedWithCapital =
      capitalTileKey != null && portTileKey == capitalTileKey;
  if (!coLocatedWithTown && !coLocatedWithCapital) {
    return (x: px, y: py);
  }

  for (final d in kPortIconSeaNeighborDeltas) {
    final nx = townX + d.$1;
    final ny = townY + d.$2;
    if (nx < 0 || ny < 0 || nx >= tileMap.width || ny >= tileMap.height) {
      continue;
    }
    final cellId = tileMap.cell(nx, ny);
    if (seaZoneIds.contains(cellId)) {
      return (x: nx, y: ny);
    }
  }
  return (x: px, y: py);
}
