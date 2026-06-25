import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/connectivity_tile_helpers.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('xyFromTileKey', () {
    test('parses grid coordinates from a well-formed tile key (positive)', () {
      final xy = xyFromTileKey('oldWorld|p1|3|4');

      expect(xy, isNotNull);
      expect(xy!.x, 3);
      expect(xy.y, 4);
    });

    test('returns null for a malformed tile key (negative)', () {
      expect(xyFromTileKey('not-a-tile-key'), isNull);
    });
  });

  group('fullProvinceIdFromTileKey', () {
    test('returns the prefixed province id from a tile key (positive)', () {
      expect(fullProvinceIdFromTileKey('newWorld|p2|0|0'), 'newWorld|p2');
    });

    test('builds the id via the canonical ProvinceId.full builder', () {
      expect(
        fullProvinceIdFromTileKey('oldWorld|p7|2|9'),
        ProvinceId.full('oldWorld', 'p7'),
      );
    });

    test('returns null for a malformed tile key (negative)', () {
      expect(fullProvinceIdFromTileKey('garbage'), isNull);
    });
  });
}
