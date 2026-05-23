/// Pins the snapshot-driven fleet-in-NW contract of
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach loop short-circuit
/// (`_fleetReachDoneFromCtSnapshotOnly`, `_harnessDetectsNonHomeFleetInNewWorld`
/// in `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) and the
/// bundled-explore readiness loop depend on this predicate to terminate
/// within the 35-turn fleet-reach cap when [ctE2eNavalPanelSnapshot]
/// reports arrival. A silent rename / fail-open here would stall the
/// suite at `_kMaxNextTurnTapsForNwFleetReach (35) × ~5 s` per scenario
/// — directly inflating the wall-clock cap #2336 is reducing.
///
/// The integration suite cannot validate this directly (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyNode, TopologyNodeType;
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

MapTopology _topologyWithSeaZone({
  required String seaId,
  required String regionId,
}) => MapTopology(
  nodes: [
    TopologyNode(id: seaId, regionId: regionId, type: TopologyNodeType.seaZone),
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
            topology: _topologyWithSeaZone(seaId: 'sea1', regionId: 'oldWorld'),
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
              topology: _emptyTopology,
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
            // Empty topology: regionId path alone must satisfy the predicate.
            topology: _emptyTopology,
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
            topology: _topologyWithSeaZone(
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
              topology: _topologyWithSeaZone(
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
            topology: _topologyWithSeaZone(seaId: 'sea_asia', regionId: 'asia'),
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
        // Two qualifying human fleets; predicate must return true without
        // requiring all of them to qualify (the iteration order pin).
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
