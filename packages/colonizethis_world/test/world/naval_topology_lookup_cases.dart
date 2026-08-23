import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/naval.dart';
import 'package:colonizethis_world/src/world/topology_helpers.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/world_test_support.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises naval topology helpers in `lib/src/world/naval.dart` and
/// topology identity APIs in `lib/src/world/topology_identity.dart` (Refs #3968).
/// SPEC/program/naval-movement-resolution.md and SPEC/game/ships-and-naval.md.
///
/// Two regions: `oldWorld` (province p1 + sea s1) and `newWorld` (province n1 +
/// sea s2). s1–s2 is a cross-region S–S warp edge.
MapTopology _topology() => prefixedDualRegionNavalWarpTopology();

void registerNavalTopologyLookupCases() {
  group('province/sea-zone lookups', () {
    final topology = _topology();

    test('firstAdjacentSeaZone returns an endpoint or null', () {
      expect(firstAdjacentSeaZone(topology, 'oldWorld|s1'), isNotNull);
      expect(firstAdjacentSeaZone(topology, 'oldWorld|orphan'), isNull);
    });

    test('seaZoneIdForProvince resolves region-scoped and global', () {
      expect(
        seaZoneIdForProvince(topology, 'p1', regionId: 'oldWorld'),
        'oldWorld|s1',
      );
      expect(seaZoneIdForProvince(topology, 'oldWorld|p1'), 'oldWorld|s1');
      expect(seaZoneIdForProvince(topology, 'p1', regionId: 'zzz'), isNull);
    });

    test('provinceIdsAdjacentToSeaZone lists coastal provinces', () {
      expect(
        provinceIdsAdjacentToSeaZone(
          topology,
          'oldWorld|s1',
          regionId: 'oldWorld',
        ),
        contains('oldWorld|p1'),
      );
    });

    test('regionIdForSeaZone resolves known and unknown sea zones', () {
      expect(regionIdForSeaZone(topology, 'oldWorld|s1'), 'oldWorld');
      expect(regionIdForSeaZone(topology, 'oldWorld|sX'), isNull);
    });

    test('seaZoneIdsAdjacentToProvince lists P–S neighbors', () {
      expect(
        seaZoneIdsAdjacentToProvince(topology, 'oldWorld|p1'),
        contains('oldWorld|s1'),
      );
    });

    test(
      'seaZoneIdsAdjacentToProvince disambiguates duplicate local province ids by region',
      () {
        final multiRegion = duplicateLocalProvinceIdsByRegionTopology();
        expect(
          seaZoneIdsAdjacentToProvince(multiRegion, 'p1', regionId: 'oldWorld'),
          {'sea1'},
        );
        expect(
          seaZoneIdsAdjacentToProvince(multiRegion, 'p1', regionId: 'newWorld'),
          {'sea2'},
        );
        expect(
          seaZoneIdForProvince(multiRegion, 'p1', regionId: 'newWorld'),
          'sea2',
        );
      },
    );
  });

  group('fleetsInPortAtProvince', () {
    test('finds fleets docked at a province (prefixed and legacy)', () {
      final worldState = TestFixtures.worldStateAtOrdersPhase(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            inPortAtProvinceId: 'oldWorld|p1',
            regionId: 'oldWorld',
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p1',
            seaZoneId: 'oldWorld|s1',
            regionId: 'oldWorld',
          ),
        ],
      );

      expect(fleetsInPortAtProvince(worldState, 'oldWorld|p1').length, 1);
      expect(fleetsInPortAtProvince(worldState, 'p1').length, 1);
      expect(fleetsInPortAtProvince(worldState, 'oldWorld|p9'), isEmpty);
    });
  });
}
