import 'package:colonizethis_models/colonizethis_models.dart' show Unit;
import 'package:colonizethis_world/src/world/region_unit_lists.dart';
import 'package:colonizethis_world/src/world_constants.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage for the `RegionUnitLists.unitListForRegion` region-dispatch
/// accessor that replaces the repeated `kRegionOldWorld` ternary (Refs #3544
/// Step 5).
void main() {
  group('RegionUnitListsAccess.unitListForRegion', () {
    final owUnit = Unit(
      id: 'u-ow',
      type: 'settler',
      ownerId: 'p1',
      locationProvinceId: '$kRegionOldWorld|a',
    );
    final nwUnit = Unit(
      id: 'u-nw',
      type: 'settler',
      ownerId: 'p1',
      locationProvinceId: '$kRegionNewWorld|a',
    );

    test('returns the old-world list for kRegionOldWorld', () {
      final RegionUnitLists lists = (ow: [owUnit], nw: [nwUnit]);
      expect(lists.unitListForRegion(kRegionOldWorld), [owUnit]);
    });

    test('returns the new-world list for kRegionNewWorld', () {
      final RegionUnitLists lists = (ow: [owUnit], nw: [nwUnit]);
      expect(lists.unitListForRegion(kRegionNewWorld), [nwUnit]);
    });

    test('returns the new-world list for any non-old-world region id', () {
      final RegionUnitLists lists = (ow: [owUnit], nw: [nwUnit]);
      expect(lists.unitListForRegion('someOtherRegion'), [nwUnit]);
    });
  });
}
