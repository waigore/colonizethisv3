/// Pins the snapshot-driven non-home-human-fleet-in-NW-coastal-sea contract
/// of [e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot] and the
/// two-tier adjacency contract of
/// [e2eNwCoastalProvincesAdjacentToFleetSea]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The bundled-explore readiness loop
/// (`_awaitNwCoastalOrVisibleLandForBundledExploreE2e` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`)
/// short-circuits on this predicate alongside
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]. Ship reveal
/// only paints coastal land for sea zones with a P–S province edge
/// (`SPEC/program/fog-and-exploration-resolution.md`), so a non-home
/// human fleet in an open-ocean NW sea satisfies
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] but never yields
/// fogged-or-better NW provinces — leaving bundled Explore disabled. A
/// silent rename / fail-open here would stall the readiness loop at
/// `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s` (Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism), directly
/// inflating the wall-clock cap #2336 is reducing.
///
/// The integration suite cannot validate this directly (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyEdge, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _human = 'gp1';
const String _otherGp = 'gp2';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData _emptyRegion = RegionData();

const Orders _emptyOrders = Orders();

const MapTopology _emptyTopology = MapTopology();

/// Build a topology where [seaId] is a NW sea zone with edges to each
/// province in [adjacentProvinceIds]. Province nodes default to NW region.
MapTopology _coastalNwTopology({
  required String seaId,
  required List<String> adjacentProvinceIds,
}) => MapTopology(
  nodes: [
    TopologyNode(
      id: seaId,
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    for (final pid in adjacentProvinceIds)
      TopologyNode(
        id: pid,
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
  ],
  edges: [
    for (final pid in adjacentProvinceIds) TopologyEdge(id1: pid, id2: seaId),
  ],
);

Game _gameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: _emptyRegion,
    newWorld: _emptyRegion,
    fleets: fleets,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _snapshot({
  required List<Fleet> fleets,
  MapTopology topology = _emptyTopology,
}) => CtE2eNavalPanelSnapshot(
  game: _gameWithFleets(fleets),
  humanPlayerId: _human,
  topology: topology,
  draftOrders: _emptyOrders,
);

Fleet _homeFleet({
  String regionId = 'oldWorld',
  String? inPortAtProvinceId = 'oldWorld|capital',
}) => Fleet(
  id: 'fleet_$_human',
  ownerId: _human,
  regionId: regionId,
  inPortAtProvinceId: inPortAtProvinceId,
);

void main() {
  suppressLogsForTests();

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
            _snapshot(fleets: const []),
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
            _snapshot(fleets: [_homeFleet()]),
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
            _snapshot(
              fleets: [
                Fleet(
                  id: 'fleet_$_human',
                  ownerId: _human,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_1',
                ),
              ],
              topology: _coastalNwTopology(
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_other_1',
                  ownerId: _otherGp,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_1',
                ),
              ],
              topology: _coastalNwTopology(
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_in_port',
                  ownerId: _human,
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
              _snapshot(
                fleets: [
                  _homeFleet(),
                  Fleet(
                    id: 'fleet_human_split',
                    ownerId: _human,
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  // Legacy state: OW regionId but the sea id is not in
                  // the topology so regionIdForSeaZone returns null.
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_phantom',
                ),
              ],
              topology: _emptyTopology,
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

  group(
    'e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — true branches',
    () {
      test('non-home human fleet with regionId == newWorld in a coastal sea '
          'returns true', () {
        expect(
          e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: _coastalNwTopology(
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: _coastalNwTopology(
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
            _snapshot(
              fleets: [
                _homeFleet(),
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
              ],
              topology: _coastalNwTopology(
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
            _snapshot(
              fleets: [
                _homeFleet(),
                // Decoy: human non-home in OW coastal sea — not NW.
                Fleet(
                  id: 'fleet_human_decoy',
                  ownerId: _human,
                  regionId: 'oldWorld',
                  seaZoneId: 'sea_ow',
                ),
                // Other-GP fleet at the qualifying NW coast — ignored.
                Fleet(
                  id: 'fleet_other_gp',
                  ownerId: _otherGp,
                  regionId: 'newWorld',
                  seaZoneId: 'sea_nw_coast',
                ),
                // Qualifying fleet last in iteration order.
                Fleet(
                  id: 'fleet_human_split',
                  ownerId: _human,
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

  group('e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot — regression '
      'guards', () {
    test('regionId casing must match exactly (`NewWorld` is rejected via '
        'topology fallback)', () {
      expect(
        e2eNonHomeHumanFleetInCoastalNewWorldSeaFromCtSnapshot(
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
                // PascalCase region id: regionIdForSeaZone short-circuit
                // is skipped and the topology must NOT resolve `NewWorld`
                // either; the predicate falls through to false.
                regionId: 'NewWorld',
                seaZoneId: 'sea_phantom',
              ),
            ],
            topology: _emptyTopology,
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
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_split',
                ownerId: _human,
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
          _snapshot(
            fleets: [
              _homeFleet(),
              Fleet(
                id: 'fleet_human_a',
                ownerId: _human,
                regionId: 'newWorld',
                seaZoneId: 'sea_nw_coast',
              ),
              Fleet(
                id: 'fleet_human_b',
                ownerId: _human,
                regionId: 'newWorld',
                seaZoneId: 'sea_nw_coast',
              ),
            ],
            topology: _coastalNwTopology(
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

  group(
    'e2eNwCoastalProvincesAdjacentToFleetSea — two-tier lookup contract',
    () {
      test('empty topology returns empty set', () {
        expect(
          e2eNwCoastalProvincesAdjacentToFleetSea(
            _emptyTopology,
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
            _coastalNwTopology(
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
            _coastalNwTopology(
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
            _coastalNwTopology(
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
            _coastalNwTopology(
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
            _coastalNwTopology(
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
