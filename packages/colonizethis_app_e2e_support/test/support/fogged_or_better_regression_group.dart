// e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — regression guards
// pins (#4344 Slice C densify).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'ct_naval_snapshot_fixtures.dart';

void registerFoggedOrBetterRegressionGroup() {
  group(
    'e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — regression guards',
    () {
      test(
        'region segment casing must match exactly (`NewWorld` rejected)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [ctNavalSnapshotNwProvince('p1')],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    // PascalCase region segment is not the canonical id.
                    'NewWorld|p1|0|0': 'fullyVisible',
                  },
                },
              ),
            ),
            isFalse,
            reason:
                'Region ids are canonical lowercase identifiers; pinning '
                'the case-sensitive `parts[0] != "newWorld"` check '
                'prevents a future regression that normalizes the segment '
                'from silently breaking NW-penetration detection.',
          );
        },
      );

      test(
        'extra `|`-segments in the tile key are rejected (returns false)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [ctNavalSnapshotNwProvince('p1')],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    // 5 parts instead of 4 — the predicate requires exactly 4.
                    'newWorld|p1|0|0|extra': 'fullyVisible',
                  },
                },
              ),
            ),
            isFalse,
            reason:
                'The 4-part tile-key contract (`regionId|localId|x|y` per '
                'SPEC/game/world-model + [ProvinceId] docs) must be '
                'enforced exactly. A regression that loosens the parser '
                'would let mis-keyed entries falsely satisfy the gate.',
          );
        },
      );

      test(
        'first fogged-or-better NW tile short-circuits — no exception on later entries',
        () {
          // Two qualifying NW visibility entries; predicate must return true
          // without requiring all of them to qualify (iteration-order pin).
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              ctNavalSnapshot(
                newWorld: RegionData(
                  provinces: [ctNavalSnapshotNwProvince('p1')],
                ),
                playerVisibilityByTile: const {
                  ctNavalSnapshotHuman: {
                    'newWorld|p1|0|0': 'fogged',
                    'newWorld|p1|1|0': 'fullyVisible',
                  },
                },
              ),
            ),
            isTrue,
            reason:
                'The predicate is existential; the first qualifying NW '
                'visibility entry flips the result to true and the rest '
                'of the map is irrelevant. Pinning two qualifying entries '
                'prevents a future regression that accidentally requires '
                '*all* NW entries to qualify.',
          );
        },
      );
    },
  );
}
