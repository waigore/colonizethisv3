import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('parseTileKeyCoordinates (colonizethis_models canonical helper)', () {
    test('parses valid tile keys into a coordinate record', () {
      final parsed = parseTileKeyCoordinates('oldWorld|P1|3|9');
      expect(parsed, isNotNull);
      expect(parsed!.regionId, 'oldWorld');
      expect(parsed.provinceLocalId, 'P1');
      expect(parsed.x, 3);
      expect(parsed.y, 9);
    });

    test('returns null when the segment count is not exactly four', () {
      expect(parseTileKeyCoordinates('oldWorld|P1|3'), isNull);
      expect(parseTileKeyCoordinates('oldWorld|P1|3|9|extra'), isNull);
      expect(parseTileKeyCoordinates(''), isNull);
    });

    test('returns null when x or y is not an integer', () {
      expect(parseTileKeyCoordinates('oldWorld|P1|x|9'), isNull);
      expect(parseTileKeyCoordinates('oldWorld|P1|3|y'), isNull);
    });

    test('preserves negative integer coordinates', () {
      final parsed = parseTileKeyCoordinates('newWorld|P2|-4|-7');
      expect(parsed, isNotNull);
      expect(parsed!.x, -4);
      expect(parsed.y, -7);
    });
  });
}
