import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group('WorldStateProvinceLookup.forEachRegion (Refs #2836 item 1)', () {
    const pOld = Province(
      id: 'oldWorld|P1',
      regionId: kRegionOldWorld,
      ownerId: 'o',
    );
    const pNew = Province(
      id: 'newWorld|P2',
      regionId: kRegionNewWorld,
      ownerId: 'n',
    );
    final uOld = Unit(
      id: 'u_old',
      type: kUnitTypeExplorer,
      ownerId: 'o',
      locationProvinceId: 'oldWorld|P1',
    );
    final uNew = Unit(
      id: 'u_new',
      type: kUnitTypeExplorer,
      ownerId: 'n',
      locationProvinceId: 'newWorld|P2',
    );

    test('invokes action exactly twice: oldWorld first, then newWorld', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
        newWorld: RegionData(provinces: const [pNew], units: [uNew]),
      );

      final seenRegionIds = <String>[];
      ws.forEachRegion((regionId, region) {
        seenRegionIds.add(regionId);
      });

      expect(seenRegionIds, [kRegionOldWorld, kRegionNewWorld]);
    });

    test('passes each region\'s data identity to the action', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
        newWorld: RegionData(provinces: const [pNew], units: [uNew]),
      );

      final seenByRegion = <String, RegionData>{};
      ws.forEachRegion((regionId, region) {
        seenByRegion[regionId] = region;
      });

      expect(identical(seenByRegion[kRegionOldWorld], ws.oldWorld), isTrue);
      expect(identical(seenByRegion[kRegionNewWorld], ws.newWorld), isTrue);
    });

    test('does not produce a new WorldState reference', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
        newWorld: RegionData(provinces: const [pNew], units: [uNew]),
      );

      final originalOld = ws.oldWorld;
      final originalNew = ws.newWorld;

      ws.forEachRegion((_, __) {});

      expect(identical(ws.oldWorld, originalOld), isTrue);
      expect(identical(ws.newWorld, originalNew), isTrue);
    });

    test('iteration order matches mapBothRegions for symmetric work', () {
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(provinces: [pOld]),
        newWorld: const RegionData(provinces: [pNew]),
      );

      final forEachOrder = <String>[];
      ws.forEachRegion((regionId, _) => forEachOrder.add(regionId));

      final mapOrder = <String>[];
      ws.mapBothRegions((regionId, region) {
        mapOrder.add(regionId);
        return region;
      });

      expect(forEachOrder, mapOrder);
    });

    test('still visits empty regions (no skip on empty provinces/units)', () {
      final ws = TestFixtures.emptyWorldState();

      var oldCalls = 0;
      var newCalls = 0;
      ws.forEachRegion((regionId, region) {
        if (regionId == kRegionOldWorld) {
          oldCalls++;
          expect(region.provinces, isEmpty);
          expect(region.units, isEmpty);
        } else if (regionId == kRegionNewWorld) {
          newCalls++;
          expect(region.provinces, isEmpty);
          expect(region.units, isEmpty);
        }
      });

      expect(oldCalls, 1);
      expect(newCalls, 1);
    });

    test(
      'symmetric processing collects entries from both regions in order',
      () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        final collected = <String>[];
        ws.forEachRegion((regionId, region) {
          for (final p in region.provinces) {
            collected.add('$regionId:${p.id}');
          }
        });

        expect(collected, ['oldWorld:oldWorld|P1', 'newWorld:newWorld|P2']);
      },
    );
  });
}
