/// Shared y → x → `tileKey` order for interactive tile-anchored markers.
/// SPEC/program/map-visualization.md. Refs #4654.
library;

int compareTileAnchoredMarkerOrder({
  required int aY,
  required int bY,
  required int aX,
  required int bX,
  required String aTileKey,
  required String bTileKey,
}) {
  final y = aY.compareTo(bY);
  if (y != 0) {
    return y;
  }
  final x = aX.compareTo(bX);
  if (x != 0) {
    return x;
  }
  return aTileKey.compareTo(bTileKey);
}

void sortTileAnchoredMarkers<T>(
  List<T> markers, {
  required int Function(T marker) yOf,
  required int Function(T marker) xOf,
  required String Function(T marker) tileKeyOf,
}) {
  markers.sort(
    (a, b) => compareTileAnchoredMarkerOrder(
      aY: yOf(a),
      bY: yOf(b),
      aX: xOf(a),
      bX: xOf(b),
      aTileKey: tileKeyOf(a),
      bTileKey: tileKeyOf(b),
    ),
  );
}
