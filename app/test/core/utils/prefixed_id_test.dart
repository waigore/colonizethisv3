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
}
