// e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — true branches pins
// (#4344 Slice C densify).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'ct_naval_snapshot_fixtures.dart';

void registerFoggedOrBetterTrueGroup() {
  group(
    'e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — true branches',
    () {
      test('single fogged NW tile returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
              playerVisibilityByTile: const {
                ctNavalSnapshotHuman: {'newWorld|p1|0|0': 'fogged'},
              },
            ),
          ),
          isTrue,
          reason:
              'A single fogged tile in a known NW province is the '
              'minimal canonical signal — the bundled-explore readiness '
              'loop must short-circuit so the assign-Explore probe can '
              'fire on the next turn.',
        );
      });

      test('single fullyVisible NW tile returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
              playerVisibilityByTile: const {
                ctNavalSnapshotHuman: {'newWorld|p1|2|3': 'fullyVisible'},
              },
            ),
          ),
          isTrue,
          reason:
              'A fully-visible NW tile is strictly stronger than fogged '
              'and must equally satisfy the gate. The predicate excludes '
              'only `unknown`, so both higher visibility levels short-'
              'circuit identically.',
        );
      });

      test('mixed unknown + fogged NW tiles still returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
              playerVisibilityByTile: const {
                ctNavalSnapshotHuman: {
                  'newWorld|p1|0|0': 'unknown',
                  'newWorld|p1|1|0': 'unknown',
                  'newWorld|p1|2|0': 'fogged',
                },
              },
            ),
          ),
          isTrue,
          reason:
              'The predicate is existential: a single fogged-or-better '
              'tile is enough, regardless of how many unknown siblings '
              'share the visibility map. Pinning the mixed case prevents '
              'a regression that accidentally requires all NW tiles to '
              'be fogged-or-better.',
        );
      });

      test('OW visible + NW fogged returns true (NW arm fires)', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              oldWorld: RegionData(
                provinces: [ctNavalSnapshotOwProvince('ow1')],
              ),
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
              playerVisibilityByTile: const {
                ctNavalSnapshotHuman: {
                  'oldWorld|ow1|0|0': 'fullyVisible',
                  'newWorld|p1|0|0': 'fogged',
                },
              },
            ),
          ),
          isTrue,
          reason:
              'Mixed OW + NW visibility must still flip to true on the '
              'NW arm. The OW tile is ignored by the `parts[0] != '
              '"newWorld"` skip; the NW tile satisfies the gate.',
        );
      });

      test(
        'multi-province NW: only one province has visibility (returns true)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [
                    ctNavalSnapshotNwProvince('p1'),
                    ctNavalSnapshotNwProvince('p2'),
                    ctNavalSnapshotNwProvince('p3'),
                  ],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    // Only p2 has any visibility; p1 and p3 stay unknown.
                    'newWorld|p2|0|0': 'fogged',
                  },
                },
              ),
            ),
            isTrue,
            reason:
                'Any NW province in the snapshot set is eligible — the '
                'predicate is existential across the whole NW region, not '
                'per-province. A single fogged tile in any tracked NW '
                'province must satisfy the gate.',
          );
        },
      );
    },
  );
}
