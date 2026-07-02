import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_world/src/world/province_traversal.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('forEachWorldRegion', () {
    test('invokes action once per region', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(
          provinces: [Province(id: 'oldWorld|p1', regionId: kRegionOldWorld)],
        ),
        newWorld: RegionData(
          provinces: [Province(id: 'newWorld|p1', regionId: kRegionNewWorld)],
        ),
      );

      final seen = <String>[];
      forEachWorldRegion(world, (regionId, _) => seen.add(regionId));
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });

  group('ownerByProvinceIdMap (Refs #2560)', () {
    test('covers both regions and preserves null ownerId entries', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(id: 'oldWorld|p2', regionId: kRegionOldWorld),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|p9',
              regionId: kRegionNewWorld,
              ownerId: 'gp2',
            ),
            Province(id: 'newWorld|p10', regionId: kRegionNewWorld),
          ],
        ),
      );

      final byOwner = ownerByProvinceIdMap(world);

      expect(byOwner, {
        'oldWorld|p1': 'gp1',
        'oldWorld|p2': null,
        'newWorld|p9': 'gp2',
        'newWorld|p10': null,
      });
    });

    test('matches the inline traverseProvinces idiom it replaces', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: kRegionOldWorld,
              ownerId: 'gp3',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|p9',
              regionId: kRegionNewWorld,
              ownerId: 'gp2',
            ),
          ],
        ),
      );

      final inline = <String, String?>{
        for (final e in traverseProvinces(world)) e.provinceId: e.ownerId,
      };
      final viaHelper = ownerByProvinceIdMap(world);

      expect(viaHelper, equals(inline));
    });
  });

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

group('WorldState mapBothRegions', () {
    test('invokes update for old then new with stable region ids', () {
      const p = Province(
        id: 'oldWorld|P1',
        regionId: kRegionOldWorld,
        ownerId: 'o',
      );
      const ow = RegionData(provinces: [p], units: const []);
      const nw = RegionData(provinces: const [], units: const []);
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: ow,
        newWorld: nw,
      );

      final seen = <String>[];
      final next = ws.mapBothRegions((regionId, region) {
        seen.add(regionId);
        if (regionId == kRegionOldWorld) {
          return RegionData(
            provinces: [region.provinces.single.copyWith(ownerId: 'x')],
            units: region.units,
          );
        }
        return region;
      });

      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
      expect(next.oldWorld.provinces.single.ownerId, 'x');
      expect(next.newWorld, nw);
    });
  });

  group('WorldState mapBothRegionUnits', () {
    test('maps units in both regions independently', () {
      final u1 = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'a',
        tileKey: 'oldWorld|P1|0|0',
        locationProvinceId: 'oldWorld|P1',
      );
      final u2 = Unit(
        id: 'u2',
        type: kUnitTypeExplorer,
        ownerId: 'a',
        tileKey: 'newWorld|P2|0|0',
        locationProvinceId: 'newWorld|P2',
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: RegionData(units: [u1]),
        newWorld: RegionData(units: [u2]),
      );

      final next = ws.mapBothRegionUnits((regionId, units) {
        if (regionId == kRegionOldWorld) {
          return [units.single.copyWith(ownerId: 'b')];
        }
        return units;
      });

      expect(next.oldWorld.units.single.ownerId, 'b');
      expect(next.newWorld.units.single.ownerId, 'a');
    });
  });

group(
    'WorldStateProvinceLookup.regionDataForIdOrThrow (Refs #2836 item 1)',
    () {
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

      test('returns oldWorld region by identity for kRegionOldWorld', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        final region = ws.regionDataForIdOrThrow(kRegionOldWorld);

        expect(identical(region, ws.oldWorld), isTrue);
        expect(region.provinces.single.id, 'oldWorld|P1');
      });

      test('returns newWorld region by identity for kRegionNewWorld', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        final region = ws.regionDataForIdOrThrow(kRegionNewWorld);

        expect(identical(region, ws.newWorld), isTrue);
        expect(region.provinces.single.id, 'newWorld|P2');
      });

      test('throws StateError on unknown regionId with id in message', () {
        final ws = TestFixtures.emptyWorldState();

        expect(
          () => ws.regionDataForIdOrThrow('mars'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('mars'),
            ),
          ),
        );
      });

      test('throws StateError on empty regionId', () {
        final ws = TestFixtures.emptyWorldState();

        expect(() => ws.regionDataForIdOrThrow(''), throwsA(isA<StateError>()));
      });

      test('agrees with nullable regionDataForId for canonical regionIds', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        expect(
          identical(
            ws.regionDataForIdOrThrow(kRegionOldWorld),
            ws.regionDataForId(kRegionOldWorld),
          ),
          isTrue,
        );
        expect(
          identical(
            ws.regionDataForIdOrThrow(kRegionNewWorld),
            ws.regionDataForId(kRegionNewWorld),
          ),
          isTrue,
        );
      });

      test('returns empty regions for empty world state without throwing', () {
        final ws = TestFixtures.emptyWorldState();

        final ow = ws.regionDataForIdOrThrow(kRegionOldWorld);
        final nw = ws.regionDataForIdOrThrow(kRegionNewWorld);

        expect(ow.provinces, isEmpty);
        expect(ow.units, isEmpty);
        expect(nw.provinces, isEmpty);
        expect(nw.units, isEmpty);
      });
    },
  );

}
