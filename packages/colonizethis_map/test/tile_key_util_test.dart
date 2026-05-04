import 'package:colonizethis_map/src/tile_key_util.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('tryParseMapTileKey', () {
    test('parses standard region|province|x|y key', () {
      final parsed = tryParseMapTileKey('oldWorld|p4|12|7');
      expect(parsed, isNotNull);
      expect(parsed!.regionId, 'oldWorld');
      expect(parsed.localId, 'p4');
      expect(parsed.x, 12);
      expect(parsed.y, 7);
    });

    test('returns null for malformed key', () {
      expect(tryParseMapTileKey('oldWorld|p4|12'), isNull);
      expect(tryParseMapTileKey('oldWorld|p4|x|7'), isNull);
    });
  });

  group('tryParseMapTileKeySuffixXY', () {
    test('parses x/y from last key segments', () {
      final parsed = tryParseMapTileKeySuffixXY('oldWorld|p4|harbor|12|7');
      expect(parsed, isNotNull);
      expect(parsed!.x, 12);
      expect(parsed.y, 7);
    });

    test('returns null when suffix x/y is invalid', () {
      expect(tryParseMapTileKeySuffixXY('oldWorld|p4|12'), isNull);
      expect(tryParseMapTileKeySuffixXY('oldWorld|p4|12|y'), isNull);
    });
  });
}
