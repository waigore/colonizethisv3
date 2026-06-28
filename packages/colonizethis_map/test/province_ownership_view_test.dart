import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_map/src/province_ownership_view.dart';
import 'package:colonizethis_test/test.dart';

Province _province(String id, {String? ownerId}) =>
    Province(id: id, regionId: 'ow', ownerId: ownerId);

void main() {
  group('provinceOwnerByIdFromProvinces', () {
    test('maps owned provinces to their owner id', () {
      final provinces = [
        _province('ow|p1', ownerId: 'faction_a'),
        _province('ow|p2', ownerId: 'faction_b'),
      ];
      expect(
        provinceOwnerByIdFromProvinces(provinces),
        equals({'ow|p1': 'faction_a', 'ow|p2': 'faction_b'}),
      );
    });

    test('keys by the province id (prefixed) as-is', () {
      final provinces = [_province('nw|coastal_3', ownerId: 'faction_c')];
      expect(
        provinceOwnerByIdFromProvinces(provinces),
        equals({'nw|coastal_3': 'faction_c'}),
      );
    });

    test('excludes provinces with a null owner', () {
      final provinces = [
        _province('ow|p1', ownerId: 'faction_a'),
        _province('ow|p2'),
      ];
      final result = provinceOwnerByIdFromProvinces(provinces);
      expect(result, equals({'ow|p1': 'faction_a'}));
      expect(result.containsKey('ow|p2'), isFalse);
    });

    test('excludes provinces with an empty owner string', () {
      final provinces = [
        _province('ow|p1', ownerId: ''),
        _province('ow|p2', ownerId: 'faction_b'),
      ];
      final result = provinceOwnerByIdFromProvinces(provinces);
      expect(result, equals({'ow|p2': 'faction_b'}));
      expect(result.containsKey('ow|p1'), isFalse);
    });

    test('empty province list yields empty map', () {
      expect(provinceOwnerByIdFromProvinces(const []), isEmpty);
    });
  });
}
