// ignore_for_file: deprecated_member_use

import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void registerProvinceLookupByIdRegionCases() {
  group('WorldStateProvinceLookup.mutableProvinceListsByRegion '
      '(Refs #2836 AC 5)', () {
    test('returns both regions keyed by canonical region ids', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Owned],
        newProvinces: [pNew1Gp1, pNew2],
      );

      final result = ws.mutableProvinceListsByRegion();

      expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
      expect(result[kRegionOldWorld], [pOld1, pOld2Owned]);
      expect(result[kRegionNewWorld], [pNew1Gp1, pNew2]);
    });

    test('returns empty lists for empty regions', () {
      final ws = makeWorld();

      final result = ws.mutableProvinceListsByRegion();

      expect(result[kRegionOldWorld], isEmpty);
      expect(result[kRegionNewWorld], isEmpty);
    });

    test('returned lists are independent copies — mutating does not change '
        'source WorldState', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Owned],
        newProvinces: [pNew1Gp1],
      );

      final result = ws.mutableProvinceListsByRegion();
      result[kRegionOldWorld]!.clear();
      result[kRegionNewWorld]!.add(pNew2);

      expect(ws.oldWorld.provinces, [pOld1, pOld2Owned]);
      expect(ws.newWorld.provinces, [pNew1Gp1]);
    });

    test('two successive calls produce independent list copies (no shared '
        'mutable state between calls)', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Owned],
        newProvinces: [pNew1Gp1],
      );

      final first = ws.mutableProvinceListsByRegion();
      final second = ws.mutableProvinceListsByRegion();

      expect(
        identical(first[kRegionOldWorld], second[kRegionOldWorld]),
        isFalse,
      );
      expect(
        identical(first[kRegionNewWorld], second[kRegionNewWorld]),
        isFalse,
      );

      first[kRegionOldWorld]!.add(pOld1);
      expect(second[kRegionOldWorld], [pOld1, pOld2Owned]);
    });
  });

  group('WorldStateProvinceLookup.regionsInOrder (Refs #3710)', () {
    test('yields old world first, then new world, with their region data', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(identical(entries[0].region, ws.oldWorld), isTrue);
      expect(identical(entries[1].region, ws.newWorld), isTrue);
    });

    test('still yields both regions when one has no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(entries[1].region.provinces, isEmpty);
    });
  });

  group('cross-region traversal stays consistent with regionsInOrder', () {
    test('allProvinces equals regionsInOrder province concatenation '
        '(old-then-new)', () {
      final ws = makeWorld(
        oldProvinces: [pOld1, pOld2Bare],
        newProvinces: [pNew1Gp2],
      );

      final viaRegions = [
        for (final entry in ws.regionsInOrder) ...entry.region.provinces,
      ];

      expect(ws.allProvinces().toList(), viaRegions);
      expect(allProvinces(ws).toList(), viaRegions);
      expect(ws.allProvinces().toList(), [pOld1, pOld2Bare, pNew1Gp2]);
    });

    test('forEachRegion visits regions in regionsInOrder order', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1Gp2]);

      final seen = <String>[];
      ws.forEachRegion((regionId, _) => seen.add(regionId));

      expect(seen, ws.regionsInOrder.map((e) => e.regionId).toList());
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });
}
