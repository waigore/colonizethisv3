// e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — regression pins (Slice D / #4195).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'coastal_nw_fleet_snapshot_fixtures.dart';

void registerCoastalNwPredicateRegressionGroup() {
  group('e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — regression '
      'guards', () {
    test('regionId casing must match exactly (`NewWorld` is rejected via '
        'topology fallback)', () {
      expect(
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          coastalNwSnapshot(
            fleets: [
              coastalNwHomeFleet(),
              Fleet(
                id: 'fleetcoastalNwHumanPlayerId_split',
                ownerId: coastalNwHumanPlayerId,
                // PascalCase region id: regionIdForSeaZone short-circuit
                // is skipped and the topology must NOT resolve `NewWorld`
                // either; the predicate falls through to false.
                regionId: 'NewWorld',
                seaZoneId: 'sea_phantom',
              ),
            ],
            topology: coastalNwEmptyTopology,
          ),
        ),
        isFalse,
        reason:
            'Region ids are canonical lowercase identifiers; an '
            'accidental `NewWorld` (PascalCase) is not a real game '
            'state, but pinning the case-sensitive contract prevents '
            'a future regression that normalizes the input from '
            'silently short-circuiting coastal-sea detection.',
      );
    });

    test('topology resolving to a non-NW region keeps result false', () {
      expect(
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          coastalNwSnapshot(
            fleets: [
              coastalNwHomeFleet(),
              Fleet(
                id: 'fleetcoastalNwHumanPlayerId_split',
                ownerId: coastalNwHumanPlayerId,
                regionId: 'oldWorld',
                seaZoneId: 'sea_asia_coast',
              ),
            ],
            topology: const MapTopology(
              nodes: [
                TopologyNode(
                  id: 'sea_asia_coast',
                  regionId: 'asia',
                  type: TopologyNodeType.seaZone,
                ),
                TopologyNode(
                  id: 'asia|p1',
                  regionId: 'asia',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: [TopologyEdge(id1: 'asia|p1', id2: 'sea_asia_coast')],
            ),
          ),
        ),
        isFalse,
        reason:
            'Future-region (e.g. `asia`) coastal sea zones must not '
            'be confused for NW; the predicate only returns true '
            'when the resolved region is exactly `newWorld`.',
      );
    });

    test('first qualifying fleet short-circuits — no exception on later '
        'fleets', () {
      expect(
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          coastalNwSnapshot(
            fleets: [
              coastalNwHomeFleet(),
              Fleet(
                id: 'fleetcoastalNwHumanPlayerId_a',
                ownerId: coastalNwHumanPlayerId,
                regionId: 'newWorld',
                seaZoneId: 'sea_nw_coast',
              ),
              Fleet(
                id: 'fleetcoastalNwHumanPlayerId_b',
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
            'Existential check: the first qualifying human fleet '
            'flips the result to true and the rest of the list is '
            'irrelevant. Pinning two qualifying entries prevents a '
            'future regression that accidentally requires *all* '
            'fleets to qualify.',
      );
    });
  });
}
