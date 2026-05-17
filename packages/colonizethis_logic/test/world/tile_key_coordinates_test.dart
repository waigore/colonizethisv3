import 'package:colonizethis_logic/src/world/tile_key_coordinates.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('parseTileKeyCoordinates (world canonical helper)', () {
    test('parses valid tile keys', () {
      final parsed = parseTileKeyCoordinates('oldWorld|P1|3|9');
      expect(parsed, isNotNull);
      expect(parsed!.regionId, 'oldWorld');
      expect(parsed.provinceLocalId, 'P1');
      expect(parsed.x, 3);
      expect(parsed.y, 9);
    });

    test('returns null for malformed tile keys', () {
      expect(parseTileKeyCoordinates('oldWorld|P1|3'), isNull);
      expect(parseTileKeyCoordinates('oldWorld|P1|x|9'), isNull);
      expect(parseTileKeyCoordinates('oldWorld|P1|3|y'), isNull);
    });
  });
}
