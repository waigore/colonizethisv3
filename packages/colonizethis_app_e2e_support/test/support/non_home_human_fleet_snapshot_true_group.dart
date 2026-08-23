// True-branch and regression pins for
// e2eNonHomeHumanFleetInNewWorldFromCtSnapshot (Refs #4598 Slice C).
library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_naval_snapshot_fixtures.dart';

const String _human = ctNavalSnapshotHuman;
const String _otherGp = ctNavalSnapshotOtherGp;
final _snapshot = ctNavalSnapshot;
final _homeFleet = ctNavalSnapshotHomeFleet;

void registerNonHomeHumanFleetSnapshotTrueGroup() {
  group('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot — true branches', () {
    test('non-home human fleet with regionId == newWorld returns true', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                regionId: 'newWorld',
                seaZoneId: 'sea_nw_1',
              ),
            ],
            topology: ctNavalSnapshotEmptyTopology,
          ),
        ),
        isTrue,
        reason:
            'A non-home human fleet whose `regionId` is already `newWorld` '
            'is the canonical arrival signal — short-circuit before '
            'consulting the topology so the post-warp scenario terminates '
            'the loop on the first matching fleet.',
      );
    });

    test('non-home human fleet with OW regionId but NW seaZone via topology '
        'returns true', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                regionId: 'oldWorld',
                seaZoneId: 'sea_nw_2',
              ),
            ],
            topology: ctNavalSnapshotTopologyWithSeaZone(
              seaId: 'sea_nw_2',
              regionId: 'newWorld',
            ),
          ),
        ),
        isTrue,
        reason:
            'The topology fallback handles the legacy fleet states that '
            'still carry the OW `regionId` while their `seaZoneId` is '
            'already a NW sea node — fleet-reach must terminate in this '
            'case too, otherwise the loop overruns the wall-clock cap '
            'while the fleet is already in NW seas.',
      );
    });

    test(
      'multi-fleet snapshot: matching fleet later in the list returns true',
      () {
        expect(
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_decoy',
                  ownerId: _human,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_ow',
                ),
                Fleet(
                  id: 'fleet_other',
                  ownerId: _otherGp,
                  regionId: 'newWorld',
                ),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  regionId: 'newWorld',
                ),
              ],
              topology: ctNavalSnapshotTopologyWithSeaZone(
                seaId: 'sea_ow',
                regionId: 'oldWorld',
              ),
            ),
          ),
          isTrue,
          reason:
              'The predicate must iterate every fleet before giving up; a '
              'qualifying fleet that follows non-qualifying ones (decoy OW '
              'fleet + other-GP fleet ignored) must still flip the result '
              'to true — order independence within the human-player slice.',
        );
      },
    );
  });
}

void registerNonHomeHumanFleetSnapshotRegressionGroup() {
  group('e2eNonHomeHumanFleetInNewWorldFromCtSnapshot — regression guards', () {
    test('regionId casing must match exactly (`NewWorld` is rejected)', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                regionId: 'NewWorld',
              ),
            ],
          ),
        ),
        isFalse,
        reason:
            'Region ids are canonical lowercase identifiers; an accidental '
            '`NewWorld` (PascalCase) is not a real game state, but pinning '
            'the case-sensitive contract prevents a future regression that '
            'normalizes the input from silently breaking fleet-reach '
            'detection.',
      );
    });

    test('topology resolving to a non-NW region keeps result false', () {
      expect(
        e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                regionId: 'oldWorld',
                seaZoneId: 'sea_asia',
              ),
            ],
            topology: ctNavalSnapshotTopologyWithSeaZone(
              seaId: 'sea_asia',
              regionId: 'asia',
            ),
          ),
        ),
        isFalse,
        reason:
            'Future-region (e.g. `asia`) sea zones must not be confused '
            'for NW; the predicate only returns true when '
            '`regionIdForSeaZone` returns exactly `newWorld`.',
      );
    });

    test(
      'first matching fleet short-circuits — no exception on later fleets',
      () {
        expect(
          e2eNonHomeHumanFleetInNewWorldFromCtSnapshot(
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_a',
                  ownerId: _human,
                  regionId: 'newWorld',
                ),
                Fleet(
                  id: 'fleet_human_b',
                  ownerId: _human,
                  regionId: 'newWorld',
                ),
              ],
            ),
          ),
          isTrue,
          reason:
              'The predicate is an existential check; the first qualifying '
              'human fleet flips the result to true and the rest of the '
              'list is irrelevant. Pinning two qualifying entries prevents '
              'a future regression that accidentally requires *all* fleets '
              'to qualify.',
        );
      },
    );
  });
}
