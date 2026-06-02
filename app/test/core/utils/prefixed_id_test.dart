import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();
  group('prefixedIdLocalSegment', () {
    test('returns suffix after first pipe', () {
      expect(prefixedIdLocalSegment('oldWorld|p1'), 'p1');
      expect(prefixedIdLocalSegment('sea:oldWorld|sz1'), 'sz1');
    });

    test('returns original when unprefixed', () {
      expect(prefixedIdLocalSegment('p1'), 'p1');
      expect(prefixedIdLocalSegment(''), '');
    });

    test('allows empty suffix when delimiter exists', () {
      expect(prefixedIdLocalSegment('oldWorld|'), '');
    });
  });

  group('prefixedIdRegionSegment', () {
    test('returns prefix before first pipe', () {
      expect(prefixedIdRegionSegment('oldWorld|p1'), 'oldWorld');
    });

    test('returns null when unprefixed', () {
      expect(prefixedIdRegionSegment('p1'), isNull);
    });
  });

  group('prefixedIdHasDelimiter', () {
    test('detects delimiter', () {
      expect(prefixedIdHasDelimiter('a|b'), isTrue);
      expect(prefixedIdHasDelimiter('ab'), isFalse);
    });
  });

  group('tryParseTileKey', () {
    test('parses a well-formed tile key', () {
      final parsed = tryParseTileKey('oldWorld|p1|3|7');
      expect(parsed, isNotNull);
      expect(parsed!.regionId, 'oldWorld');
      expect(parsed.provinceLocalId, 'p1');
      expect(parsed.x, 3);
      expect(parsed.y, 7);
      expect(parsed.prefixedProvinceId, 'oldWorld|p1');
    });

    test('parses x=0,y=0 coords', () {
      final parsed = tryParseTileKey('newWorld|p9|0|0');
      expect(parsed, isNotNull);
      expect(parsed!.x, 0);
      expect(parsed.y, 0);
    });

    test('returns null for null and empty inputs', () {
      expect(tryParseTileKey(null), isNull);
      expect(tryParseTileKey(''), isNull);
    });

    test('returns null when fewer than four segments', () {
      expect(tryParseTileKey('p1'), isNull);
      expect(tryParseTileKey('oldWorld|p1'), isNull);
      expect(tryParseTileKey('oldWorld|p1|3'), isNull);
    });

    test('returns null for empty regionId or empty provinceLocalId', () {
      expect(tryParseTileKey('|p1|3|7'), isNull);
      expect(tryParseTileKey('oldWorld||3|7'), isNull);
    });

    test('returns null when coords are non-integer', () {
      expect(tryParseTileKey('oldWorld|p1|x|7'), isNull);
      expect(tryParseTileKey('oldWorld|p1|3|y'), isNull);
      expect(tryParseTileKey('oldWorld|p1|3|'), isNull);
    });

    test('rejects negative coords as non-integer parse only when garbage', () {
      // int.tryParse('-3') returns -3, so this should parse successfully.
      // SPEC/game/world-model-identity.md does not constrain sign here; callers
      // separately validate that x/y fall inside region.width/height.
      final parsed = tryParseTileKey('oldWorld|p1|-3|7');
      expect(parsed, isNotNull);
      expect(parsed!.x, -3);
    });
  });

  group('isTileKeyInRegion', () {
    test('returns true when tile key region matches', () {
      expect(isTileKeyInRegion('oldWorld|p1|3|7', 'oldWorld'), isTrue);
    });

    test('returns false when tile key region does not match', () {
      expect(isTileKeyInRegion('oldWorld|p1|3|7', 'newWorld'), isFalse);
    });

    test('returns false on malformed tile key', () {
      expect(isTileKeyInRegion('oldWorld|p1', 'oldWorld'), isFalse);
      expect(isTileKeyInRegion('', 'oldWorld'), isFalse);
    });
  });
}
