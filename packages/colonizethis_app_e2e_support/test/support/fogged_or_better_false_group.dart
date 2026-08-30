// e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — false branches pins
// (#4344 Slice C densify).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'ct_naval_snapshot_fixtures.dart';

void registerFoggedOrBetterFalseGroup() {
  group(
    'e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — false branches',
    () {
      test('null snapshot returns false', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(null),
          isFalse,
          reason:
              'No naval-panel snapshot plumbing this turn means the '
              'predicate must short-circuit before any field access. '
              'A fail-open here would either stall the bundled-explore '
              'readiness loop or convert the fleet-reach test\'s skip '
              'guard into an always-skip — neither is acceptable.',
        );
      });

      test('no NW provinces in the snapshot returns false', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              oldWorld: RegionData(
                provinces: [ctNavalSnapshotOwProvince('ow1')],
              ),
              playerVisibilityByTile: const {
                ctNavalSnapshotHuman: {'oldWorld|ow1|0|0': 'fullyVisible'},
              },
            ),
          ),
          isFalse,
          reason:
              'A snapshot with zero `newWorld|` provinces cannot satisfy '
              'NW-fogged-or-better even when OW tiles are fully visible. '
              'The early-exit on the empty NW province set is also a perf '
              'safeguard against building the [PlayerView] for nothing.',
        );
      });

      test('NW province exists but visibility map is empty returns false', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
            ),
          ),
          isFalse,
          reason:
              'A non-empty NW province set with no visibility entries '
              'means every tile defaults to `unknown`; the iteration must '
              'find no fogged-or-better tile and return false.',
        );
      });

      test('NW visibility entries are all `unknown` returns false', () {
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
                },
              },
            ),
          ),
          isFalse,
          reason:
              'Explicit `unknown` entries must be treated the same as '
              'absent entries; the docstring contract excludes only '
              '`unknown`, so an accidental "any visibility entry counts" '
              'regression would surface here.',
        );
      });

      test('visible OW tile does not satisfy the NW gate (returns false)', () {
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
                  'oldWorld|ow1|1|0': 'fogged',
                },
              },
            ),
          ),
          isFalse,
          reason:
              'OW tiles must not satisfy the NW gate — the predicate is '
              'specifically about NW penetration. A regression that '
              'dropped the `parts[0] != "newWorld"` skip would flip '
              'this to true and mask the bundled-explore Explore-assign '
              'requirement, which depends on NW (not OW) visibility.',
        );
      });

      test(
        'NW-region tile key with unknown province local id returns false',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [ctNavalSnapshotNwProvince('p1')],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    // Tile key references a NW province (`pPhantom`) that
                    // is **not** in the snapshot's NW province set — the
                    // predicate must skip it rather than fail-open.
                    'newWorld|pPhantom|0|0': 'fullyVisible',
                  },
                },
              ),
            ),
            isFalse,
            reason:
                'A tile key whose local-id segment is not in the snapshot '
                'NW province set must be skipped — otherwise a stale or '
                'mis-keyed visibility entry would falsely report '
                'fogged-or-better NW penetration.',
          );
        },
      );

      test(
        'tile key with fewer than four `|`-segments is skipped (returns false)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [ctNavalSnapshotNwProvince('p1')],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    // Malformed: only 3 parts.
                    'newWorld|p1|0': 'fullyVisible',
                    // Malformed: only 2 parts.
                    'newWorld|p1': 'fogged',
                  },
                },
              ),
            ),
            isFalse,
            reason:
                'Malformed tile keys must be skipped rather than crash '
                'the predicate or count as fogged-or-better. Pinning the '
                '4-part guard prevents a regression that loosens the '
                'parser from silently flipping the fleet-reach skip guard.',
          );
        },
      );

      test('visibility entry for a different player returns false', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            ctNavalSnapshot(
              newWorld: RegionData(
                provinces: [ctNavalSnapshotNwProvince('p1')],
              ),
              playerVisibilityByTile: const {
                // Only gp2 has visibility — humanPlayerId is gp1.
                ctNavalSnapshotOtherGp: {'newWorld|p1|0|0': 'fullyVisible'},
              },
            ),
          ),
          isFalse,
          reason:
              'The predicate is scoped to [snap.humanPlayerId]; another '
              'player\'s visibility must not bleed through. [buildPlayerView] '
              'reads `playerVisibilityByTile[humanPlayerId]` and ignores '
              'other player entries.',
        );
      });
    },
  );
}
