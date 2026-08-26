import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('kRegion constants', () {
    test('kRegionOldWorld is oldWorld', () {
      expect(kRegionOldWorld, 'oldWorld');
    });

    test('kRegionNewWorld is newWorld', () {
      expect(kRegionNewWorld, 'newWorld');
    });
  });
}
