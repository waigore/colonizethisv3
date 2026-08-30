// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('WorldStateProvinceLookup.forEachRegion (Refs #2836 item 1)', () {
    test('invokes action exactly twice: oldWorld first, then newWorld', () {
      final ws = traversalDualRegionWorld(
        oldUnits: [traversalUOld],
        newUnits: [traversalUNew],
      );

      final seenRegionIds = <String>[];
      ws.forEachRegion((regionId, region) {
        seenRegionIds.add(regionId);
      });

      expect(seenRegionIds, [kRegionOldWorld, kRegionNewWorld]);
    });

    test('passes each region\'s data identity to the action', () {
      final ws = traversalDualRegionWorld(
        oldUnits: [traversalUOld],
        newUnits: [traversalUNew],
      );

      final seenByRegion = <String, RegionData>{};
      ws.forEachRegion((regionId, region) {
        seenByRegion[regionId] = region;
      });

      expect(identical(seenByRegion[kRegionOldWorld], ws.oldWorld), isTrue);
      expect(identical(seenByRegion[kRegionNewWorld], ws.newWorld), isTrue);
    });

    test('does not produce a new WorldState reference', () {
      final ws = traversalDualRegionWorld(
        oldUnits: [traversalUOld],
        newUnits: [traversalUNew],
      );

      final originalOld = ws.oldWorld;
      final originalNew = ws.newWorld;

      ws.forEachRegion((_, __) {});

      expect(identical(ws.oldWorld, originalOld), isTrue);
      expect(identical(ws.newWorld, originalNew), isTrue);
    });

    test('iteration order matches mapBothRegions for symmetric work', () {
      final ws = traversalDualRegionWorld();

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
        final ws = traversalDualRegionWorld(
          oldUnits: [traversalUOld],
          newUnits: [traversalUNew],
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
