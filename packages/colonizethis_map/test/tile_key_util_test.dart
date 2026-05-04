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

  group('trySplitExactlyTwoPipeSegments', () {
    test('parses exactly two segments', () {
      expect(trySplitExactlyTwoPipeSegments('a|b'), ['a', 'b']);
      expect(trySplitExactlyTwoPipeSegments('a|b|c'), isNull);
      expect(trySplitExactlyTwoPipeSegments('a'), isNull);
    });
  });

  group('lastPipeSegment', () {
    test('returns last segment when pipes present', () {
      expect(lastPipeSegment('r|s1'), 's1');
      expect(lastPipeSegment('oldWorld|p1|2|3'), '3');
    });

    test('returns whole string when no pipe', () {
      expect(lastPipeSegment('s1'), 's1');
    });
  });

  group('tryLocalProvinceIdFromPortsSeaboardKey', () {
    test('parses three-part key with region match', () {
      expect(
        tryLocalProvinceIdFromPortsSeaboardKey('oldWorld|p9|seaboard', 'oldWorld'),
        'p9',
      );
    });

    test('returns null when region mismatches', () {
      expect(
        tryLocalProvinceIdFromPortsSeaboardKey('newWorld|p9|seaboard', 'oldWorld'),
        isNull,
      );
    });

    test('parses two-part key as local id only', () {
      expect(tryLocalProvinceIdFromPortsSeaboardKey('p9|x', 'oldWorld'), 'p9');
    });
  });
}
