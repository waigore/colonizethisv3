import 'package:colonizethis_logic/src/world/port_seaboard_registry_key.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('decodePortSeaboardRegistryKey', () {
    test('parses prefixed region|province|sea keys', () {
      final d = decodePortSeaboardRegistryKey('oldWorld|P1|seaA');
      expect(d, isNotNull);
      expect(d!.fullProvinceId, 'oldWorld|P1');
      expect(d.seaZoneId, 'seaA');
      expect(d.regionId, 'oldWorld');
      expect(d.isPrefixedKey, isTrue);
    });

    test('parses legacy provinceId|sea keys', () {
      final d = decodePortSeaboardRegistryKey('P1|seaB');
      expect(d, isNotNull);
      expect(d!.fullProvinceId, 'P1');
      expect(d.seaZoneId, 'seaB');
      expect(d.regionId, '');
      expect(d.isPrefixedKey, isFalse);
    });

    test('returns null for empty or single-segment keys', () {
      expect(decodePortSeaboardRegistryKey(''), isNull);
      expect(decodePortSeaboardRegistryKey('onlyOne'), isNull);
    });
  });
}
