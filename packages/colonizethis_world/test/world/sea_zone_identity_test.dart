import 'package:colonizethis_world/src/world/sea_zone_identity.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  group('canonicalizeSeaZoneId', () {
    test('returns the input unchanged when already prefixed for the region', () {
      final result = canonicalizeSeaZoneId(
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|sz1',
      );
      expect(result, 'oldWorld|sz1');
    });

    test('prefixes a local sea-zone id with the region', () {
      final result = canonicalizeSeaZoneId(
        regionId: 'newWorld',
        seaZoneId: 'sz9',
      );
      expect(result, 'newWorld|sz9');
    });

    test('throws when a prefixed id names a different region', () {
      expect(
        () => canonicalizeSeaZoneId(
          regionId: 'oldWorld',
          seaZoneId: 'newWorld|sz1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('isCanonicalSeaZoneId', () {
    test('true for prefixed ids', () {
      expect(isCanonicalSeaZoneId('oldWorld|sz1'), isTrue);
    });

    test('false for bare local ids', () {
      expect(isCanonicalSeaZoneId('sz1'), isFalse);
    });
  });

  group('failIfLegacyLocalSeaZoneId', () {
    test('returns normally for canonical prefixed ids', () {
      expect(
        () => failIfLegacyLocalSeaZoneId('oldWorld|sz1', context: 'test'),
        returnsNormally,
      );
    });

    test('throws StateError for legacy local ids', () {
      expect(
        () => failIfLegacyLocalSeaZoneId('sz1', context: 'test'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
