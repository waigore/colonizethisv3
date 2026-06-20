/// Pins the snapshot-driven NW-fogged-or-better contract of
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The bundled-explore readiness loop
/// (`_awaitNwCoastalOrVisibleLandForBundledExploreE2e` in
/// `new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`) and the
/// fleet-reach test's final guard
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` line ~365) depend on
/// this predicate to short-circuit once the human player has *any* NW
/// province tile fogged-or-better. A silent rename / fail-open would
/// either stall the bundled-explore readiness loop for the full 35-turn
/// cap (Bottleneck 4 in `SPEC/program/e2e-integration-tests.md`
/// § Determinism) or convert the strict bundled-explore assertion into a
/// silent skip and mask a real Explore-assign regression — both directly
/// inflate the wall-clock cap #2336 is reducing.
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology _emptyTopology = MapTopology();

const Orders _emptyOrders = Orders();

const RegionData _emptyRegion = RegionData();

Province _nwProvince(String localId) =>
    Province(id: ProvinceId.full('newWorld', localId), regionId: 'newWorld');

Province _owProvince(String localId) =>
    Province(id: ProvinceId.full('oldWorld', localId), regionId: 'oldWorld');

WorldState _world({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => WorldState(
  turnState: _orderingTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  playerVisibilityByTile: playerVisibilityByTile,
);

Game _game({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: _world(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _snapshot({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => CtE2eNavalPanelSnapshot(
  game: _game(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: _human,
  topology: _emptyTopology,
  draftOrders: _emptyOrders,
);

void main() {
  suppressLogsForTests();

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
            _snapshot(
              oldWorld: RegionData(provinces: [_owProvince('ow1')]),
              playerVisibilityByTile: const {
                _human: {'oldWorld|ow1|0|0': 'fullyVisible'},
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
            _snapshot(newWorld: RegionData(provinces: [_nwProvince('p1')])),
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
            _snapshot(
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {
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
            _snapshot(
              oldWorld: RegionData(provinces: [_owProvince('ow1')]),
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {
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
              _snapshot(
                newWorld: RegionData(provinces: [_nwProvince('p1')]),
                playerVisibilityByTile: const {
                  _human: {
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
              _snapshot(
                newWorld: RegionData(provinces: [_nwProvince('p1')]),
                playerVisibilityByTile: const {
                  _human: {
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
            _snapshot(
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                // Only gp2 has visibility — humanPlayerId is gp1.
                'gp2': {'newWorld|p1|0|0': 'fullyVisible'},
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

  group(
    'e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — true branches',
    () {
      test('single fogged NW tile returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            _snapshot(
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {'newWorld|p1|0|0': 'fogged'},
              },
            ),
          ),
          isTrue,
          reason:
              'A single fogged tile in a known NW province is the '
              'minimal canonical signal — the bundled-explore readiness '
              'loop must short-circuit so the assign-Explore probe can '
              'fire on the next turn.',
        );
      });

      test('single fullyVisible NW tile returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            _snapshot(
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {'newWorld|p1|2|3': 'fullyVisible'},
              },
            ),
          ),
          isTrue,
          reason:
              'A fully-visible NW tile is strictly stronger than fogged '
              'and must equally satisfy the gate. The predicate excludes '
              'only `unknown`, so both higher visibility levels short-'
              'circuit identically.',
        );
      });

      test('mixed unknown + fogged NW tiles still returns true', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            _snapshot(
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {
                  'newWorld|p1|0|0': 'unknown',
                  'newWorld|p1|1|0': 'unknown',
                  'newWorld|p1|2|0': 'fogged',
                },
              },
            ),
          ),
          isTrue,
          reason:
              'The predicate is existential: a single fogged-or-better '
              'tile is enough, regardless of how many unknown siblings '
              'share the visibility map. Pinning the mixed case prevents '
              'a regression that accidentally requires all NW tiles to '
              'be fogged-or-better.',
        );
      });

      test('OW visible + NW fogged returns true (NW arm fires)', () {
        expect(
          e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
            _snapshot(
              oldWorld: RegionData(provinces: [_owProvince('ow1')]),
              newWorld: RegionData(provinces: [_nwProvince('p1')]),
              playerVisibilityByTile: const {
                _human: {
                  'oldWorld|ow1|0|0': 'fullyVisible',
                  'newWorld|p1|0|0': 'fogged',
                },
              },
            ),
          ),
          isTrue,
          reason:
              'Mixed OW + NW visibility must still flip to true on the '
              'NW arm. The OW tile is ignored by the `parts[0] != '
              '"newWorld"` skip; the NW tile satisfies the gate.',
        );
      });

      test(
        'multi-province NW: only one province has visibility (returns true)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              _snapshot(
                newWorld: RegionData(
                  provinces: [
                    _nwProvince('p1'),
                    _nwProvince('p2'),
                    _nwProvince('p3'),
                  ],
                ),
                playerVisibilityByTile: const {
                  _human: {
                    // Only p2 has any visibility; p1 and p3 stay unknown.
                    'newWorld|p2|0|0': 'fogged',
                  },
                },
              ),
            ),
            isTrue,
            reason:
                'Any NW province in the snapshot set is eligible — the '
                'predicate is existential across the whole NW region, not '
                'per-province. A single fogged tile in any tracked NW '
                'province must satisfy the gate.',
          );
        },
      );
    },
  );

  group(
    'e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot — regression guards',
    () {
      test(
        'region segment casing must match exactly (`NewWorld` rejected)',
        () {
          expect(
            e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot(
              _snapshot(
                newWorld: RegionData(provinces: [_nwProvince('p1')]),
                playerVisibilityByTile: const {
                  _human: {
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
              _snapshot(
                newWorld: RegionData(provinces: [_nwProvince('p1')]),
                playerVisibilityByTile: const {
                  _human: {
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
              _snapshot(
                newWorld: RegionData(provinces: [_nwProvince('p1')]),
                playerVisibilityByTile: const {
                  _human: {
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
