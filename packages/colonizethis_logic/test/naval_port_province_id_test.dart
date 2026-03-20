import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('regionAndLocalProvinceForFleetInPort', () {
    test('prefixed id uses ProvinceId region and local', () {
      final r = regionAndLocalProvinceForFleetInPort('oldWorld|p1', 'ignored');
      expect(r.regionId, 'oldWorld');
      expect(r.localId, 'p1');
    });

    test('prefixed id keeps remainder after first pipe as local id', () {
      final r = regionAndLocalProvinceForFleetInPort('r|a|b', 'fallback');
      expect(r.regionId, 'r');
      expect(r.localId, 'a|b');
    });

    test('unprefixed id uses fleet region and full string as local', () {
      final r = regionAndLocalProvinceForFleetInPort('p1', 'newWorld');
      expect(r.regionId, 'newWorld');
      expect(r.localId, 'p1');
    });
  });
}
