// e2eNwCoastalProvincesAdjacentToFleetSea — two-tier lookup contract pins (Slice D / #4195).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'coastal_nw_fleet_snapshot_fixtures.dart';

void registerCoastalNwAdjacencyGroup() {
  group(
    'e2eNwCoastalProvincesAdjacentToFleetSea — two-tier lookup contract',
    () {
      test('empty topology returns empty set', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            coastalNwEmptyTopology,
            'sea1',
            'newWorld',
          ),
          isEmpty,
          reason:
              'No nodes / no edges means no possible adjacency; the '
              'helper must surface the empty set rather than fall '
              'through to a non-empty constant or throw.',
        );
      });

      test('verbatim local sea id matches when topology stores it as a local '
          'sea node', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            coastalNwCoastalTopology(
              seaId: 'sea_nw_coast',
              adjacentProvinceIds: const ['newWorld|p1', 'newWorld|p2'],
            ),
            'sea_nw_coast',
            'newWorld',
          ),
          equals({'newWorld|p1', 'newWorld|p2'}),
          reason:
              'The first-call verbatim lookup must succeed against a '
              'topology that stores the sea id in its local form; the '
              'returned set must include every adjacent province '
              'without filtering.',
        );
      });

      test('verbatim prefixed sea id matches when topology stores the '
          'prefixed form', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            coastalNwCoastalTopology(
              seaId: 'newWorld|sea_nw_coast',
              adjacentProvinceIds: const ['newWorld|p1'],
            ),
            'newWorld|sea_nw_coast',
            'newWorld',
          ),
          equals({'newWorld|p1'}),
          reason:
              'When the caller already passes the prefixed sea id and '
              'the topology agrees, the first-call lookup succeeds; '
              'no fallback is required.',
        );
      });

      test('local sea id falls back to the prefixed form when verbatim '
          'lookup is empty', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            coastalNwCoastalTopology(
              seaId: 'newWorld|sea_nw_coast',
              adjacentProvinceIds: const ['newWorld|p1'],
            ),
            'sea_nw_coast',
            'newWorld',
          ),
          equals({'newWorld|p1'}),
          reason:
              'This is the slice the helper exists to fix: live fleet '
              'states carry the local sea id while combined topology '
              'uses the prefixed form. The second-call fallback must '
              'discover the adjacent provinces; a regression that '
              'dropped the fallback would force every coastal lookup '
              'to fail silently and re-introduce Bottleneck 4.',
        );
      });

      test('prefixed sea id that genuinely is not in the topology returns '
          'empty without retry', () {
        // A prefixed input naming a sea zone that does not exist in the
        // topology graph (no matching node id, no matching edge) must
        // surface as an empty set. The early-return guard
        // (`!ProvinceId.isPrefixed(seaZoneId)`) prevents the second
        // call from re-prefixing an already-prefixed id (which would
        // either double-prefix into an invalid lookup or short-circuit
        // back to the same canonical form and return the same empty
        // result twice). The contract pinned here is: "prefixed input +
        // no match = empty, no second-chance lookup".
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            // Topology has a real NW coastal sea (`sea_nw_coast`) so
            // we know adjacency lookup machinery works; the input
            // names a different, non-existent prefixed sea
            // (`newWorld|sea_phantom`).
            coastalNwCoastalTopology(
              seaId: 'sea_nw_coast',
              adjacentProvinceIds: const ['newWorld|p1'],
            ),
            'newWorld|sea_phantom',
            'newWorld',
          ),
          isEmpty,
          reason:
              'Per docstring: when the caller passes a prefixed id and '
              'the verbatim lookup is empty, the helper must surface '
              'the empty set without a redundant second lookup against '
              'the same canonical form. A regression that dropped the '
              'prefix-guard and unconditionally retried with '
              '`ProvinceId.full(...)` could either double-prefix the '
              'input or silently re-canonicalize to the same form '
              '(masking genuine topology gaps).',
        );
      });

      test('bare local sea id that genuinely is not in the topology returns '
          'empty after the fallback retry', () {
        // Same shape as above but with a bare local sea id — the
        // verbatim lookup is empty AND the prefixed-retry must also
        // return empty because the sea genuinely is not in the
        // topology. Both branches must surface the empty result.
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            coastalNwCoastalTopology(
              seaId: 'sea_nw_coast',
              adjacentProvinceIds: const ['newWorld|p1'],
            ),
            'sea_phantom',
            'newWorld',
          ),
          isEmpty,
          reason:
              'The fallback retry (`ProvinceId.full(regionId, '
              'seaZoneId)`) must propagate the empty result from the '
              'underlying `provinceIdsAdjacentToSeaZone` lookup rather '
              'than substitute a non-empty default. Pinning the empty '
              'baseline catches regressions that swallow the inner '
              'empty set and fall through to a non-empty constant.',
        );
      });

      test('region scoping rejects cross-region edges', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            // OW edge sharing the same local sea id; the NW lookup
            // must not surface the OW province.
            const MapTopology(
              nodes: [
                TopologyNode(
                  id: 'sea1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.seaZone,
                ),
                TopologyNode(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  type: TopologyNodeType.province,
                ),
              ],
              edges: [TopologyEdge(id1: 'oldWorld|p1', id2: 'sea1')],
            ),
            'sea1',
            'newWorld',
          ),
          isEmpty,
          reason:
              'The helper passes `regionId` through to '
              '`provinceIdsAdjacentToSeaZone`, which is region-scoped '
              '(world-model identity). A cross-region edge with the '
              'same local id must not leak into the NW adjacency set.',
        );
      });
    },
  );
}
