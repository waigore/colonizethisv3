/// Shared grid centroid math for province tile keys and sea-zone marker placement.
/// SPEC/game/capital-and-connectivity.md § Town per province; sea-zone fleet markers.

/// Parses the last two `|` segments of [tileKey] as integer grid coordinates.
/// Expects canonical tile keys `regionId|localProvinceOrSeaId|x|y` (at least four segments).
(int x, int y)? parseTileKeyCellXY(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) return null;
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  if (x == null || y == null) return null;
  return (x, y);
}

/// Arithmetic mean of integer coordinates per axis, each rounded (half away from zero).
/// Matches averaging all cells in a sea zone or all tiles in a province.
({int x, int y})? roundedCentroidIntCoords(Iterable<(int x, int y)> points) {
  var sumX = 0;
  var sumY = 0;
  var n = 0;
  for (final p in points) {
    sumX += p.$1;
    sumY += p.$2;
    n++;
  }
  if (n == 0) return null;
  return (x: (sumX / n).round(), y: (sumY / n).round());
}

/// Centroid of tile-key cell coordinates; skips keys that do not parse.
({int x, int y})? roundedCentroidFromTileKeys(Iterable<String> tileKeys) {
  final pts = <(int, int)>[];
  for (final k in tileKeys) {
    final xy = parseTileKeyCellXY(k);
    if (xy != null) pts.add(xy);
  }
  return roundedCentroidIntCoords(pts);
}
