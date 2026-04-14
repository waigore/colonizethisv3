import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('grid_centroid', () {
    test('parseTileKeyCellXY reads last two segments', () {
      expect(parseTileKeyCellXY('oldWorld|p2|2|2'), (2, 2));
      expect(parseTileKeyCellXY('short'), isNull);
      expect(parseTileKeyCellXY('a|b|c'), isNull);
    });

    test('roundedCentroidIntCoords matches mean with per-axis rounding', () {
      expect(roundedCentroidIntCoords([(0, 0), (2, 0), (2, 2)]), (x: 1, y: 1));
      expect(roundedCentroidIntCoords([(1, 0), (2, 0), (2, 1)]), (x: 2, y: 0));
      expect(roundedCentroidIntCoords([]), isNull);
    });

    test('roundedCentroidFromTileKeys skips bad keys', () {
      expect(
        roundedCentroidFromTileKeys([
          'oldWorld|p2|0|0',
          'bad',
          'oldWorld|p2|2|0',
        ]),
        (x: 1, y: 0),
      );
    });
  });
}
