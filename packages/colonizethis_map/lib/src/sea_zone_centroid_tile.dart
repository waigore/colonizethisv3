/// Deterministic centroid sea tile for a sea zone on a region tile map.
/// SPEC/ui/map-widget.md § Fleet tile markers (issue #1745).
library;

import 'package:colonizethis_data/colonizethis_data.dart';

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
  var sumX = 0;
  var sumY = 0;
  var n = 0;
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      if (tileMap.cell(x, y) != localSeaZoneId) {
        continue;
      }
      sumX += x;
      sumY += y;
      n++;
    }
  }
  if (n == 0) {
    return null;
  }
  final cx = (sumX / n).round();
  final cy = (sumY / n).round();
  return '$regionId|$localSeaZoneId|$cx|$cy';
}
