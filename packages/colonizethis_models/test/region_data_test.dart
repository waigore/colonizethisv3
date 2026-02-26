import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('RegionData', () {
    test('toJson/fromJson round-trip', () {
      const r = RegionData(
        provinces: [Province(id: 'p1', regionId: 'oldWorld', ownerId: null)],
        units: [Unit(id: 'u1', type: 'infantry', ownerId: 'p1', provinceId: 'p1')],
      );
      final r2 = RegionData.fromJson(r.toJson());
      expect(r2.provinces.length, 1);
      expect(r2.units.length, 1);
      expect(r2.units.first.type, 'infantry');
    });
  });
}
