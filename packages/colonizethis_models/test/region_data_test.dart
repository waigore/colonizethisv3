import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('RegionData', () {
    test('toJson/fromJson round-trip', () {
      final r = RegionData(
        provinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: null),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'infantry',
            ownerId: 'p1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ],
      );
      final r2 = RegionData.fromJson(r.toJson());
      expect(r2.provinces.length, 1);
      expect(r2.units.length, 1);
      expect(r2.units.first.type, 'infantry');
    });
  });
}
