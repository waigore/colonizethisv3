/// Pins the snapshot-driven Explore-Assign contract of
/// [e2eExploreAssignEnabledFromCivilianSnapshot]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach test's `_anyExplorerHasEnabledExploreAssignFleetE2e`
/// short-circuits on this predicate before scrolling the civilian panel
/// `Assign` sheet (`new_game_fleet_reaches_new_world_e2e_helpers_part2.dart`).
/// A silent rename / fail-open here would either:
///
///   - Force the panel-sweep loop to fall through to the
///     `maxPanelSweepSteps (16) × per-step Assign sweep` slow path on every
///     fleet-reach turn — burning frames on a deterministic short-circuit
///     the snapshot already provides (Bottleneck 5 in
///     `SPEC/program/e2e-integration-tests.md` § Determinism, #2336 AC5); or
///   - Convert the strict Explore-Assign affordance assertion into a silent
///     "always enabled" / "always disabled" verdict and mask a real
///     bundled-Explore regression.
///
/// The `null` return path is contractually distinct from the `false` return
/// path: the caller treats `null` as "no civilian-panel snapshot plumbed for
/// this turn — fall back to the live walk" while `false` is the definitive
/// "panel mounted but no civilian can be assigned Explore right now"
/// verdict. Conflating the two would either skip the slow-path fallback
/// when the snapshot is missing (false negative) or trigger the slow-path
/// fallback when the snapshot already says `false` (wasted frames).
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test layer
/// carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetExplore,
        kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

WorldState _world() => const WorldState(
  turnState: _orderingTurn,
  oldWorld: RegionData(),
  newWorld: RegionData(),
);

Game _game() => Game(
  id: 'g1',
  worldState: _world(),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _snapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

void main() {
  suppressLogsForTests();

  group('e2eExploreAssignEnabledFromCivilianSnapshot — null branch', () {
    test('null snapshot returns null (NOT false)', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(null),
        isNull,
        reason:
            'No civilian-panel snapshot plumbing this turn must surface '
            'as `null` so the caller (`_anyExplorerHasEnabledExploreAssignFleetE2e`) '
            'falls back to the live panel walk instead of treating the '
            'missing snapshot as a definitive "enabled" / "disabled" '
            'verdict. Returning `false` here would silently skip the '
            'slow-path fallback and surface a false bundled-Explore '
            '"disabled" reading whenever the panel is mid-mount.',
      );
    });
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — false branches', () {
    test('empty availableWorkTargets returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(_snapshot()),
        isFalse,
        reason:
            'A mounted civilian panel with zero unit rows is a definitive '
            '"panel mounted but no civilian can be assigned anything" '
            'verdict — the caller skips the slow-path Assign sweep. '
            'Returning `null` here would force an unnecessary panel-sweep '
            'on every fleet-reach turn.',
      );
    });

    test('single unit row with no explore target returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad, kWorkTargetProspect],
            },
          ),
        ),
        isFalse,
        reason:
            'A unit row with valid non-Explore work targets still does '
            'not satisfy the predicate — the panel-sweep fallback would '
            'find no Explore tile either, so `false` is the deterministic '
            'short-circuit.',
      );
    });

    test('multiple unit rows none with explore target returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
              'unit-2': [kWorkTargetProspect, kWorkTargetBuildImprovement],
              'unit-3': <String>[],
            },
          ),
        ),
        isFalse,
        reason:
            'Iteration walks every value list before returning false; an '
            'early return on the first non-matching row would skip later '
            'rows that could legitimately surface Explore (regression '
            'guard against accidental short-circuit on the false arm).',
      );
    });

    test('empty target lists for all rows returns false', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': <String>[],
              'unit-2': <String>[],
            },
          ),
        ),
        isFalse,
        reason:
            'Empty target lists are valid panel states (every unit is '
            'busy / idle without an Explore-capable type). The predicate '
            'must traverse them without spuriously returning `true`.',
      );
    });
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — true branches', () {
    test('single unit row with only explore returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Single Explorer with only Explore available is the canonical '
            'short-circuit case — the slow-path Assign sweep would find '
            'the same affordance enabled.',
      );
    });

    test(
      'single unit row with explore among multiple targets returns true',
      () {
        expect(
          e2eExploreAssignEnabledFromCivilianSnapshot(
            _snapshot(
              availableWorkTargets: const {
                'explorer-1': [
                  kWorkTargetProspect,
                  kWorkTargetExplore,
                  kWorkTargetBuildRoad,
                ],
              },
            ),
          ),
          isTrue,
          reason:
              'Membership uses `List.contains`, so any list containing '
              '`explore` qualifies regardless of position. Order should '
              'not affect the verdict.',
        );
      },
    );

    test('multiple unit rows with explore in only one returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
              'unit-2': [kWorkTargetProspect],
              'explorer-3': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'A single Explore-enabled unit row among non-Explore peers '
            'is sufficient — the panel only needs one assign affordance '
            'to satisfy the bundled-Explore readiness gate.',
      );
    });

    test('multiple unit rows all with explore returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore, kWorkTargetProspect],
              'explorer-2': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Fully Explore-enabled panel state — the existential check '
            'returns true on the first match, which is the documented '
            'short-circuit behavior.',
      );
    });

    test('explore mixed with empty target lists returns true', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': <String>[],
              'unit-2': <String>[],
              'explorer-3': [kWorkTargetExplore],
            },
          ),
        ),
        isTrue,
        reason:
            'Empty target lists are skipped by `List.contains(...)` and '
            'must not short-circuit the iteration on the false arm; the '
            'trailing Explore row must still be discovered.',
      );
    });
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — regression guards', () {
    test('case-sensitive: `Explore` (PascalCase) rejected', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': ['Explore'],
            },
          ),
        ),
        isFalse,
        reason:
            'Work-target ids are exact-match strings (logic-side '
            '`kWorkTargetExplore == \'explore\'`). A future code change '
            'that loosens comparison (e.g. ignore-case) would surface '
            'phantom matches against UI labels rather than the canonical '
            'target id — this pin keeps the comparison strict.',
      );
    });

    test('case-sensitive: `EXPLORE` (uppercase) rejected', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': ['EXPLORE'],
            },
          ),
        ),
        isFalse,
        reason:
            'Symmetric uppercase guard alongside the PascalCase case — '
            'pins the lower-case-only contract from both directions.',
      );
    });

    test('substring `exploration` does not satisfy the predicate', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          _snapshot(
            availableWorkTargets: const {
              'unit-1': ['exploration'],
            },
          ),
        ),
        isFalse,
        reason:
            '`List.contains` performs exact equality. A future change '
            'that accidentally swaps to a `startsWith` / `Iterable.any` '
            'with substring matching would surface this regression here.',
      );
    });

    test('first-qualifying unit short-circuits (existential, not '
        'universal)', () {
      // The lifted helper is documented to short-circuit on the FIRST
      // matching unit-row entry, not to walk every list and reduce.
      // Pin the existential contract by surfacing a match in the
      // first iteration position and a non-match (with a deliberately
      // weird target id that would NOT survive a future strict-equality
      // regression) later in the map. The predicate must NOT consult
      // the trailing entry's content beyond the `List.contains` check
      // (no all-rows reduction, no aggregation).
      final snap = _snapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
          'unit-2': ['EXPLORE_ALL_NOT_A_REAL_TARGET'],
        },
      );
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(snap),
        isTrue,
        reason:
            'Existential short-circuit on the first qualifying row — '
            'a universal-all-rows variant would walk the trailing '
            'placeholder list and still need to return true on the '
            'first match anyway, but the pin against `EXPLORE_ALL_*` '
            'guards against any future code that uses the trailing '
            'entry value to re-derive truthiness.',
      );
    });
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — determinism', () {
    test('identical input snapshots yield identical results', () {
      final snapA = _snapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
          'explorer-2': [kWorkTargetExplore],
        },
      );
      final snapB = _snapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
          'explorer-2': [kWorkTargetExplore],
        },
      );

      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(snapA),
        e2eExploreAssignEnabledFromCivilianSnapshot(snapB),
        reason:
            'Refs #2336 / Must-have AC1: predicates lifted into '
            'shared library MUST be deterministic. Two structurally '
            'identical snapshots must produce structurally identical '
            'outputs (no hidden state or global access in the lifted '
            'helper).',
      );
    });

    test('repeated calls on same snapshot yield identical results', () {
      final snap = _snapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetExplore],
        },
      );
      final first = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      final second = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      final third = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      expect(
        [first, second, third],
        everyElement(equals(true)),
        reason:
            'Determinism for repeated calls on the same input — pins '
            'absence of memoization / mutable state in the predicate.',
      );
    });
  });
}
