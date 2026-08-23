// False-branch pins for e2eNonHomeHumanFleetInNewWorldFromCtSnapshot.
// Extracted from the pin suite so the host stays under the wave-4 test
// densify target (Refs #4598 Slice C).
library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_naval_snapshot_fixtures.dart';

const String _human = ctNavalSnapshotHuman;
const String _otherGp = ctNavalSnapshotOtherGp;
final _snapshot = ctNavalSnapshot;
final _homeFleet = ctNavalSnapshotHomeFleet;

void registerNonHomeHumanFleetSnapshotFalseGroup() {
  group('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot — false branches', () {
    test('null snapshot returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(null),
        isFalse,
        reason:
            'No naval-panel snapshot plumbing this turn means the loop must '
            'keep iterating (no short-circuit). A regression to fail-open '
            'would terminate the fleet-reach loop on turn 0 before the '
            'split fleet has had a chance to move.',
      );
    });

    test('no fleets in the snapshot returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(fleets: const []),
        ),
        isFalse,
        reason:
            'An empty fleet list cannot satisfy non-home-fleet-in-NW; the '
            'predicate must keep iterating instead of treating "no fleets" '
            'as arrival.',
      );
    });

    test('only home fleet (in port, OW region) returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(fleets: [_homeFleet()]),
        ),
        isFalse,
        reason:
            'The home fleet (`fleet_<humanPlayerId>`) is skipped per the '
            'docstring contract; otherwise the fleet-reach loop would '
            'short-circuit on turn 0 before the player splits / sails to '
            'the New World.',
      );
    });

    test(
      'only home fleet at NW region is still skipped (home-id wins over region)',
      () {
        expect(
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
            _snapshot(
              fleets: [
                Fleet(
                  id: 'fleet_$_human',
                  ownerId: _human,
                  regionId: 'newWorld',
                  seaZoneId: 'newWorld|sea1',
                ),
              ],
            ),
          ),
          isFalse,
          reason:
              'The home-fleet skip is by **id**, not by location: a home '
              'fleet whose location is NW (after warp + before split) must '
              'not falsely report arrival, otherwise the split-then-sail '
              'scenario short-circuits before the non-home fleet is in NW.',
        );
      },
    );

    test('non-home fleet owned by a different GP returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_other_1',
                ownerId: _otherGp,
                regionId: 'newWorld',
                seaZoneId: 'newWorld|sea1',
              ),
            ],
          ),
        ),
        isFalse,
        reason:
            'Only the human player\'s non-home fleets count. Any other GP '
            'sailing in NW must not be confused for the human\'s fleet '
            'arrival.',
      );
    });

    test('non-home human fleet in OW (regionId + sea zone) returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                regionId: 'oldWorld',
                seaZoneId: 'sea1',
              ),
            ],
            topology: ctNavalSnapshotTopologyWithSeaZone(
              seaId: 'sea1',
              regionId: 'oldWorld',
            ),
          ),
        ),
        isFalse,
        reason:
            'A non-home human fleet in an OW sea zone, with its `regionId` '
            'also OW, must not trigger the NW short-circuit; the split '
            'fleet is still in OW until it crosses the warp boundary.',
      );
    });

    test(
      'non-home human fleet with OW regionId and an unknown sea zone returns false',
      () {
        expect(
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_phantom',
                ),
              ],
              topology: ctNavalSnapshotEmptyTopology,
            ),
          ),
          isFalse,
          reason:
              'When the topology cannot resolve a sea zone\'s region '
              '(`regionIdForSeaZone` returns null), the predicate must keep '
              'iterating rather than fail-open. An empty topology must not '
              'be treated as "in NW" for any fleet.',
        );
      },
    );

    test('non-home human fleet in port (no sea zone) at OW returns false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_in_port',
                ownerId: _human,
                regionId: 'oldWorld',
                inPortAtProvinceId: 'oldWorld|port1',
              ),
            ],
          ),
        ),
        isFalse,
        reason:
            'A non-home fleet in port at OW has a null `seaZoneId`; the '
            'predicate must not attempt to resolve it through the topology '
            'and must keep returning false until the fleet actually moves '
            'into a NW sea zone.',
      );
    });
  });
}
