// Unique province-lookup contracts ported from logic orphan (Refs #4090 Slice B).
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(
      provinces: [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'Alpha'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', displayName: 'Beta'),
      ],
    ),
    newWorld: const RegionData(
      provinces: [
        Province(id: 'newWorld|n1', regionId: 'newWorld', displayName: 'Gamma'),
      ],
    ),
  );

  final worldWithLegacyUnprefixedProvince = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(
      provinces: [
        Province(id: 'p1', regionId: 'oldWorld', displayName: 'Legacy Alpha'),
      ],
    ),
    newWorld: const RegionData(),
  );

  group('tryGetRegionIdForLegacyProvinceKey (unique ports)', () {
    test('resolves legacy short province id to oldWorld', () {
      expect(
        worldWithLegacyUnprefixedProvince.tryGetRegionIdForLegacyProvinceKey(
          'p1',
        ),
        kRegionOldWorld,
      );
    });

    test('prefers oldWorld when same id string exists in both regions', () {
      final dup = WorldState(
        turnState: world.turnState,
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'dup', regionId: 'oldWorld', displayName: 'A'),
          ],
        ),
        newWorld: const RegionData(
          provinces: [
            Province(id: 'dup', regionId: 'newWorld', displayName: 'B'),
          ],
        ),
      );
      expect(dup.tryGetRegionIdForLegacyProvinceKey('dup'), kRegionOldWorld);
    });
  });

  group('tryGetProvince / tryGetProvinceByRegion null matrix', () {
    test('tryGetProvince returns null for unknown / malformed ids', () {
      expect(world.tryGetProvince('oldWorld|missing'), isNull);
      expect(world.tryGetProvince('unknownRegion|p1'), isNull);
      expect(world.tryGetProvince('oldWorld|'), isNull);
    });

    test('tryGetProvinceByRegion returns null for missing in region', () {
      expect(world.tryGetProvinceByRegion('oldWorld', 'missing'), isNull);
      expect(world.tryGetProvinceByRegion('unknownRegion', 'p1'), isNull);
    });

    test('does not match legacy unprefixed province ids in region lookup', () {
      expect(
        () => worldWithLegacyUnprefixedProvince.getProvinceByRegion(
          'oldWorld',
          'p1',
        ),
        throwsStateError,
      );
      expect(
        worldWithLegacyUnprefixedProvince.tryGetProvinceByRegion(
          'oldWorld',
          'p1',
        ),
        isNull,
      );
    });
  });

  group('updateRegionById preserve peer region', () {
    test('updates oldWorld and preserves newWorld', () {
      final updated = world.updateRegionById(
        kRegionOldWorld,
        (region) => RegionData(
          provinces: [
            ...region.provinces,
            const Province(
              id: 'oldWorld|p3',
              regionId: 'oldWorld',
              displayName: 'Delta',
            ),
          ],
          units: region.units,
        ),
      );
      expect(updated.oldWorld.provinces, hasLength(3));
      expect(updated.oldWorld.provinces.last.id, 'oldWorld|p3');
      expect(updated.newWorld.provinces, hasLength(1));
      expect(updated.newWorld.provinces.first.id, 'newWorld|n1');
    });
  });

  group('provinceListIndexOfProvinceId', () {
    test('returns first index on duplicate ids and null when absent', () {
      const dupA = Province(id: 'dup', regionId: 'oldWorld', displayName: 'First');
      const dupB = Province(id: 'dup', regionId: 'oldWorld', displayName: 'Second');
      final provinces = [dupA, dupB];
      expect(provinceListIndexOfProvinceId(provinces, 'dup'), 0);
      expect(
        provinceListIndexOfProvinceId(world.oldWorld.provinces, 'oldWorld|missing'),
        isNull,
      );
    });
  });
}
