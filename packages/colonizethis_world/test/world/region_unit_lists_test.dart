import 'package:colonizethis_models/colonizethis_models.dart'
    show RegionData, TurnPhase, TurnState, Unit, WorldState;
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

  group('WorldStateRegionUnitLists.mutableRegionUnitLists', () {
    test('returns independent mutable copies of both region unit lists', () {
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
      final ws = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(units: [owUnit]),
        newWorld: RegionData(units: [nwUnit]),
      );

      final lists = ws.mutableRegionUnitLists();
      lists.ow.add(
        Unit(
          id: 'u-ow-2',
          type: 'settler',
          ownerId: 'p1',
          locationProvinceId: '$kRegionOldWorld|b',
        ),
      );

      expect(ws.oldWorld.units, [owUnit]);
      expect(lists.ow.map((u) => u.id), ['u-ow', 'u-ow-2']);
      expect(lists.nw, [nwUnit]);
    });
  });
}
