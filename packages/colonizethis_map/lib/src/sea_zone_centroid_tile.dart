/// Deterministic centroid sea tile for a sea zone on a region tile map.
/// SPEC/ui/map-widget.md § Fleet tile markers (issue #1745).
library;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_grid.dart';

/// Returns tile key `regionId|localSeaZoneId|x|y` for the cell whose coordinates
/// are `round(average x)`, `round(average y)` over all grid cells assigned to
/// [localSeaZoneId] on [tileMap].
String? seaZoneCentroidTileKey({
  required TileMapResult tileMap,
  required String regionId,
  required String localSeaZoneId,
  required Set<String> seaZoneNodeIds,
}) {
  if (!seaZoneNodeIds.contains(localSeaZoneId)) {
    return null;
  }
  final points = <(int, int)>[];
  TileMapGrid.forEachIndex(tileMap.height, tileMap.width, (y, x) {
    if (tileMap.cell(x, y) != localSeaZoneId) {
      return;
    }
    points.add((x, y));
  });
  final c = roundedCentroidIntCoords(points);
  if (c == null) {
    return null;
  }
  return '$regionId|$localSeaZoneId|${c.x}|${c.y}';
}
