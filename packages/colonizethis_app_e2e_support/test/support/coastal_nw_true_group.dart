// e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — true branches pins (Slice D / #4195).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'coastal_nw_fleet_snapshot_fixtures.dart';

void registerCoastalNwPredicateTrueGroup() {
  group(
    'e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — true branches',
    () {
      test('non-home human fleet with regionId == newWorld in a coastal sea '
          'returns true', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: coastalNwCoastalTopology(
                seaId: 'sea_nw_coast',
                adjacentProvinceIds: const ['newWorld|p1'],
              ),
            ),
          ),
          isTrue,
          reason:
              'Canonical readiness signal: a non-home human fleet in '
              'a NW sea zone that has at least one P–S edge means ship '
              'reveal will paint coastal land. The readiness loop '
              'short-circuits, the orchestrator proceeds to bundled '
              'Explore — exactly the path this predicate guards.',
        );
      });

      test('non-home human fleet with OW regionId but NW coastal sea via '
          'topology returns true', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: coastalNwCoastalTopology(
                seaId: 'sea_nw_coast',
                adjacentProvinceIds: const ['newWorld|p1'],
              ),
            ),
          ),
          isTrue,
          reason:
              'Legacy fleet state may still carry the OW `regionId` '
              'while the `seaZoneId` is a NW sea node — the topology '
              'fallback (`regionIdForSeaZone == newWorld`) must keep '
              'this coastal path live, otherwise the readiness loop '
              'overruns the wall-clock cap.',
        );
      });

      test('local-id sea zone matches prefixed P–S edge via the two-tier '
          'fallback', () {
        // Live fleet states sometimes carry the local sea id (`sea5`)
        // while the combined topology uses the prefixed P–S form
        // (`newWorld|sea5`); the lifted
        // `e2eNwCoastalProvincesAdjacentToFleetSea` two-tier lookup
        // exists precisely for this case.
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: coastalNwCoastalTopology(
                seaId: 'newWorld|sea_nw_coast',
                adjacentProvinceIds: const ['newWorld|p1'],
              ),
            ),
          ),
          isTrue,
          reason:
              'The two-tier fallback must keep coastal detection '
              'aligned with the ship-reveal contract regardless of '
              'whether the fleet carries the local or prefixed sea id; '
              'a regression that dropped the fallback would force '
              'every fleet to refresh its sea id schema before the '
              'readiness loop terminates.',
        );
      });

      test('multi-fleet snapshot: matching fleet later in the list still '
          'returns true', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            coastalNwSnapshot(
              fleets: [
                coastalNwHomeFleet(),
                // Decoy: human non-home in OW coastal sea — not NW.
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_decoy',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_ow',
                ),
                // Other-GP fleet at the qualifying NW coast — ignored.
                Fleet(
                  id: 'fleet_other_gp',
                  ownerId: coastalNwOtherGpId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
                // Qualifying fleet last in iteration order.
                Fleet(
                  id: 'fleetcoastalNwHumanPlayerId_split',
                  ownerId: coastalNwHumanPlayerId,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: MapTopology(
                nodes: const [
                  TopologyNode(
                    id: 'sea_ow',
                    regionId: 'oldWorld',
                    type: TopologyNodeType.seaZone,
                  ),
                  TopologyNode(
                    id: 'sea_nw_coast',
                    regionId: 'newWorld',
                    type: TopologyNodeType.seaZone,
                  ),
                  TopologyNode(
                    id: 'newWorld|p1',
                    regionId: 'newWorld',
                    type: TopologyNodeType.province,
                  ),
                ],
                edges: const [
                  TopologyEdge(id1: 'newWorld|p1', id2: 'sea_nw_coast'),
                ],
              ),
            ),
          ),
          isTrue,
          reason:
              'The predicate must iterate every fleet before giving '
              'up; a qualifying fleet that follows non-qualifying '
              'ones (OW decoy, other-GP fleet) must still flip the '
              'result to true — pin existential semantics, not '
              'first-fleet-only.',
        );
      });
    },
  );
}
