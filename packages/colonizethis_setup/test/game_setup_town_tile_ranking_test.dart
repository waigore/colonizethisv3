import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('compareTownTileCandidates', () {
    test('prefers tile closer to centroid when BFS equal', () {
      const cx = 5;
      const cy = 5;
      const bfs = <String, int>{};
      final a = 'r|p|5|5';
      final b = 'r|p|0|0';
      expect(
        compareTownTileCandidates(a, b, centroidX: cx, centroidY: cy, bfsFromCapital: bfs),
        lessThan(0),
      );
    });

    test('breaks ties with lexicographic tile key when centroid and BFS tie', () {
      const cx = 5;
      const cy = 5;
      const bfs = <String, int>{};
      final closerLex = 'r|p|4|5';
      final fartherLex = 'r|p|6|5';
      expect(
        compareTownTileCandidates(
          closerLex,
          fartherLex,
          centroidX: cx,
          centroidY: cy,
          bfsFromCapital: bfs,
        ),
        lessThan(0),
      );
    });
  });

  group('pickTownTileByCentroidAndBfs', () {
    test('returns sole candidate', () {
      expect(
        pickTownTileByCentroidAndBfs(
          candidates: const ['r|p|0|0'],
          centroidX: 0,
          centroidY: 0,
          bfsFromCapital: const {},
        ),
        'r|p|0|0',
      );
    });
  });
}
