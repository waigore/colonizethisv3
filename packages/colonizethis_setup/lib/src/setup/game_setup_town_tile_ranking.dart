// SPEC/program/game-setup-pipeline.md §7d — town tile ranking (centroid, BFS tie-break).
import 'package:colonizethis_data/colonizethis_data.dart';

({int x, int y}) provinceTownCentroidFromTileKeys(List<String> tiles) {
  final c = roundedCentroidFromTileKeys(tiles);
  if (c != null) return c;
  final xy = parseTileKeyCellXY(tiles.first);
  return (x: xy?.$1 ?? 0, y: xy?.$2 ?? 0);
}

int compareTownTileCandidates(
  String a,
  String b, {
  required int centroidX,
  required int centroidY,
  required Map<String, int> bfsFromCapital,
}) {
  final da = tileDistanceSquaredToCentroid(a, centroidX: centroidX, centroidY: centroidY);
  final db = tileDistanceSquaredToCentroid(b, centroidX: centroidX, centroidY: centroidY);
  if (da != db) return da.compareTo(db);
  final ba = bfsDistanceOrUnreachable(a, bfsFromCapital);
  final bb = bfsDistanceOrUnreachable(b, bfsFromCapital);
  if (ba != bb) return ba.compareTo(bb);
  return a.compareTo(b);
}

int tileDistanceSquaredToCentroid(
  String tileKey, {
  required int centroidX,
  required int centroidY,
}) {
  final xy = parseTileKeyCellXY(tileKey);
  if (xy == null) return 1 << 30;
  final dx = xy.$1 - centroidX;
  final dy = xy.$2 - centroidY;
  return dx * dx + dy * dy;
}

int bfsDistanceOrUnreachable(String tileKey, Map<String, int> bfsFromCapital) {
  const unreachable = 999999;
  return bfsFromCapital[tileKey] ?? unreachable;
}

String pickTownTileByCentroidAndBfs({
  required List<String> candidates,
  required int centroidX,
  required int centroidY,
  required Map<String, int> bfsFromCapital,
}) {
  return candidates.reduce(
    (best, candidate) => compareTownTileCandidates(
          candidate,
          best,
          centroidX: centroidX,
          centroidY: centroidY,
          bfsFromCapital: bfsFromCapital,
        ) <
        0
        ? candidate
        : best,
  );
}
