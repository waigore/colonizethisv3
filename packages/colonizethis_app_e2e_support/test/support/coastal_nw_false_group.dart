// e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — false branches pins (Slice D / #4195).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'coastal_nw_fleet_snapshot_fixtures.dart';

void registerCoastalNwPredicateFalseGroup() {
  group(
    'e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — false branches',
    () {
      test('null snapshot returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(null),
          isFalse,
          reason:
              'No naval-panel snapshot plumbing this turn means the '
              'predicate must short-circuit before any field access. '
              'A fail-open would terminate the bundled-explore '
              'readiness loop on turn 0 before the split fleet has '
              'reached coastal NW.',
        );
      });

      test('no fleets in the snapshot returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(fleets: const []),
          ),
          isFalse,
          reason:
              'An empty fleet list cannot satisfy non-home-human-coastal-NW; '
              'the predicate must keep iterating instead of treating '
              '"no fleets" as arrival.',
        );
      });

      test('only home fleet (in port, OW region) returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(fleets: [coastalNwHomeFleet()]),
          ),
          isFalse,
          reason:
              'The home fleet (`fleet_<humanPlayerId>`) is skipped per '
              'the docstring contract; otherwise the readiness loop '
              'would short-circuit on turn 0 before the player splits '
              'and sails to the New World.',
        );
      });

      test('home fleet sitting in a NW coastal sea is still skipped '
          '(home-id wins over location)', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                Fleet(
                  id: 'fleet_$coastalNwHumanPlayerId',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_1',
                ),
              ],
              topology: coastalNwCoastalTopology(
                seaId: 'sea_nw_1',
                adjacentProvinceIds: const ['newWorld|p1'],
              ),
            ),
          ),
          isFalse,
          reason:
              'The home-fleet skip is by **id**, not by location: a '
              'home fleet in a coastal NW sea (after warp + before '
              'split) must not falsely report arrival, otherwise the '
              'split-then-sail scenario short-circuits before the '
              'non-home fleet is in NW coastal seas.',
        );
      });

      test('non-home fleet owned by a different GP returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleet_other_1',
                  ownerId: coastalNwOtherGpId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_1',
                ),
              ],
              topology: coastalNwCoastalTopology(
                seaId: 'sea_nw_1',
                adjacentProvinceIds: const ['newWorld|p1'],
              ),
            ),
          ),
          isFalse,
          reason:
              'Only the human player\'s non-home fleets count. Any '
              'other GP sailing in NW coastal sea must not be confused '
              'for the human\'s readiness signal.',
        );
      });

      test('non-home human fleet in port (no sea zone) returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_in_port',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'newWorld',
                  inPortAtProvinceId: 'newWorld|port1',
                ),
              ],
            ),
          ),
          isFalse,
          reason:
              'A non-home fleet in port has `isAtSea == false` and a '
              'null `seaZoneId`; the predicate must skip per contract '
              'rather than attempt adjacency lookup against a null '
              'identifier or treat the in-port state as coastal-sea '
              'arrival.',
        );
      });

      test(
        'non-home human fleet in NW open-ocean (no P–S edge) returns false',
        () {
          expect(
            e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
              coastalNwSnapshot(
                fleets: [
                  coastalNwHomeFleet(),
                  Fleet(
                    id: 'fleetcoastalNwHumanPlayerId_split',
                    ownerId: coastalNwHumanPlayerId,
                    regionId: 'newWorld',
                    seaZoneId: 'sea_open_ocean',
                  ),
                ],
                // Topology declares the sea zone but no adjacent province
                // edges — open-ocean sea with no coastal land.
                topology: const MapTopology(
                  nodes: [
                    TopologyNode(
                      id: 'sea_open_ocean',
                      regionId: 'newWorld',
                      type: TopologyNodeType.seaZone,
                    ),
                  ],
                ),
              ),
            ),
            isFalse,
            reason:
                'This is the canonical fail mode the coastal predicate '
                'exists to guard against: a fleet in open-ocean NW '
                'satisfies "fleet is in NW" but never paints coastal '
                'land (no P–S edge), so bundled Explore stays disabled. '
                'A fail-open here would stall the readiness loop for the '
                'full 35-turn cap.',
          );
        },
      );

      test('non-home human fleet in OW coastal sea returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_ow_coast',
                ),
              ],
              topology: const MapTopology(
                nodes: [
                  TopologyNode(
                    id: 'sea_ow_coast',
                    regionId: 'oldWorld',
                    type: TopologyNodeType.seaZone,
                  ),
                  TopologyNode(
                    id: 'oldWorld|p1',
                    regionId: 'oldWorld',
                    type: TopologyNodeType.province,
                  ),
                ],
                edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'sea_ow_coast')],
              ),
            ),
          ),
          isFalse,
          reason:
              'A non-home human fleet in an OW coastal sea zone must '
              'not satisfy the NW-coastal predicate; the readiness '
              'loop must keep iterating until the fleet actually '
              'crosses the warp boundary into a NW coastal sea.',
        );
      });

      test('non-home human fleet at a sea zone the topology cannot resolve '
          'returns false', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  // Legacy state: OW regionId but the sea id is not in
                  // the topology so regionIdForSeaZone returns null.
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_phantom',
                ),
              ],
              topology: coastalNwEmptyTopology,
            ),
          ),
          isFalse,
          reason:
              'When `regionIdForSeaZone` returns null (sea not in '
              'topology) and `regionId` is not `newWorld`, the '
              'predicate must skip the fleet rather than assume any '
              'region or fail open.',
        );
      });
    },
  );
}
