import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('ProvinceId', () {
    test('regionIdFrom returns prefix segment', () {
      expect(ProvinceId.regionIdFrom('oldWorld|p1'), 'oldWorld');
    });

    test('localIdFrom returns suffix segment', () {
      expect(ProvinceId.localIdFrom('oldWorld|p1'), 'p1');
    });

    test('localIdFrom allows empty suffix when delimiter exists', () {
      expect(ProvinceId.localIdFrom('oldWorld|'), '');
    });

    test('regionIdFrom throws for unprefixed id', () {
      expect(() => ProvinceId.regionIdFrom('p1'), throwsStateError);
    });

    test('full builds prefixed id', () {
      expect(ProvinceId.full('newWorld', 'n3'), 'newWorld|n3');
    });

    test('isPrefixed identifies full IDs', () {
      expect(ProvinceId.isPrefixed('oldWorld|p1'), isTrue);
      expect(ProvinceId.isPrefixed('p1'), isFalse);
    });

    test('prefixed IDs can be normalized by explicit handling', () {
      expect(
        ProvinceId.isPrefixed('oldWorld|p1')
            ? ProvinceId.localIdFrom('oldWorld|p1')
            : 'oldWorld|p1',
        'p1',
      );
      const storedLocalId = 'p1';
      expect(
        ProvinceId.isPrefixed(storedLocalId)
            ? ProvinceId.localIdFrom('oldWorld|p1')
            : storedLocalId,
        'p1',
      );
    });
  });
}
