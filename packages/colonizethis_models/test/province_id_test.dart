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

    test('localIdFrom throws for unprefixed id', () {
      expect(() => ProvinceId.localIdFrom('p1'), throwsStateError);
    });

    test('full builds prefixed id', () {
      expect(ProvinceId.full('newWorld', 'n3'), 'newWorld|n3');
    });

    test('isPrefixed identifies full IDs', () {
      expect(ProvinceId.isPrefixed('oldWorld|p1'), isTrue);
      expect(ProvinceId.isPrefixed('p1'), isFalse);
    });
  });
}
