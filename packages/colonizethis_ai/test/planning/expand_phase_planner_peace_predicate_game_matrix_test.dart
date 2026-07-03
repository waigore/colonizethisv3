// Table-driven matrix consolidation of the EXPAND `(game, snapshot) -> bool`
// peace-predicate pins (Refs #3749 branch-pin consolidation, companion to the
// scalar predicate matrix in
// `expand_phase_planner_below_quota_peace_predicate_matrix_test.dart` and the
// decider matrix in `expand_phase_planner_peace_target_decider_matrix_test.dart`).
//
// This single file replaces three former per-predicate `*_branches_test.dart`
// suites that each pinned one EXPAND `bool` predicate from
// `expand_phase_planner.dart` (re-exported from `colonial_pressure.dart`) with
// one `test(...)` per branch:
//
//   - `expand_phase_planner_stalled_ow_gp_blocker_focus_branches_test.dart`
//   - `expand_phase_planner_can_pivot_from_sole_gp_war_branches_test.dart`
//   - `expand_phase_planner_has_uninvaded_minor_branches_test.dart`
//
// All three pinned predicates share the exact signature
// `({required Game game, required AIWorldSnapshot snapshot}) -> bool`, so each
// former branch case becomes one matrix row here with byte-equivalent fixture
// inputs (Old/New World province ownership, player/minor/tribe roster, the
// planning GP id, at-war list, own OW count, and the invadable frontier) and
// the same verbatim expected value + regression `reason`. Coverage is preserved
// 1:1 — every former assertion has a corresponding row — while the per-file
// scaffolding collapses into one shared `_buildGame` / `_snapshot` harness and
// three table-driven loops. See each original suite's history for the full
// per-branch rationale; the `reason` text on each row carries the regression it
// guards. The two former determinism guards (repeated-call stability) are kept
// verbatim in a dedicated group below.
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI) — EXPAND
// diplomacy targeting (stalled OW GP-blocker focus, sole-GP-war pivot
// availability, and the uninvaded-OW-minor first-peace gate; Refs #2509).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp5 = 'gp5';
const String _gp6 = 'gp6';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';
const String _tribe1 = 'tribe1';

const List<Player> _gp5gp6 = <Player>[
  Player(id: _gp5, displayName: 'P5', isHuman: false),
  Player(id: _gp6, displayName: 'P6', isHuman: false),
];
const List<Player> _gp1gp2 = <Player>[
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
  Player(id: _gp2, displayName: 'GP2', isHuman: false),
];
const List<Player> _gp1only = <Player>[
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
];

/// `count` Old World provinces owned by [owner], ids `oldWorld|<owner>_<i>`
/// starting at index [start]. Only province *ownership* is read by these
/// predicates (`getProvinceOwnerMap` / the minor-roster OW scan), so synthetic
/// filler ids are arbitrary except where a row's [_Case.invadable] list
/// references a specific id (those are added explicitly in the row).
List<Province> _ow(String owner, int count, {int start = 0}) => <Province>[
  for (var i = start; i < start + count; i++)
    Province(id: 'oldWorld|${owner}_$i', regionId: 'oldWorld', ownerId: owner),
];

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
class _Case {
  const _Case({
    required this.name,
    required this.players,
    required this.playerId,
    required this.owProvinces,
    required this.ow,
    required this.expected,
    this.nwProvinces = const <Province>[],
    this.minorNations = const <MinorNation>[],
    this.tribes = const <Tribe>[],
    this.atWarWith = const <String>[],
    this.invadable = const <String>[],
    this.turnNumber = 80,
    this.reason,
  });

  final String name;
  final List<Player> players;
  final String playerId;
  final List<Province> owProvinces;
  final int ow;
  final bool expected;
  final List<Province> nwProvinces;
  final List<MinorNation> minorNations;
  final List<Tribe> tribes;
  final List<String> atWarWith;
  final List<String> invadable;
  final int turnNumber;
  final String? reason;
}

Game _buildGame(_Case c) => Game(
  id: 'g-expand-peace-predicate-matrix',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: c.turnNumber),
    oldWorld: RegionData(provinces: c.owProvinces),
    newWorld: RegionData(provinces: c.nwProvinces),
  ),
  players: c.players,
  minorNations: c.minorNations,
  tribes: c.tribes,
);

AIWorldSnapshot _snapshot(_Case c) => AIWorldSnapshot(
  playerId: c.playerId,
  threats: ThreatSummary(atWarWith: c.atWarWith),
  opportunities: const OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: c.ow,
    invadableProvinceIdsSorted: c.invadable,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

typedef _PredicateFn = bool Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

void _runPredicate(String label, _PredicateFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        expect(
          fn(game: _buildGame(c), snapshot: _snapshot(c)),
          c.expected ? isTrue : isFalse,
          reason: c.reason,
        );
      });
    }
  });
}

const Province _gp6Frontier = Province(
  id: 'oldWorld|gp6_frontier',
  regionId: 'oldWorld',
  ownerId: _gp6,
);

void main() {
  // --- isStalledOldWorldGpBlockerFocus (gp5/gp6 roster, GP-only frontier). ---
  _runPredicate('isStalledOldWorldGpBlockerFocus (truth table)',
      isStalledOldWorldGpBlockerFocus, <_Case>[
    _Case(
      name: 'false when at the observer OW quota even with a GP-only invadable '
          'frontier',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [
        ..._ow(_gp5, kObserverConquestMinOwProvincesPerGp),
        _gp6Frontier,
      ],
      ow: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const [_gp6],
      invadable: const ['oldWorld|gp6_frontier'],
      turnNumber: 60,
      expected: false,
      reason: 'at-quota short-circuit must skip the GP-only frontier delegate',
    ),
    _Case(
      name: 'false when below quota but no invadable provinces remain',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [..._ow(_gp5, 8), _gp6Frontier],
      ow: 8,
      atWarWith: const [_gp6],
      turnNumber: 60,
      expected: false,
      reason: 'empty invadable list defeats the GP-only frontier delegate',
    ),
    _Case(
      name: 'false when an invadable province is owned by a minor nation '
          '(minor pivot)',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [
        ..._ow(_gp5, 8),
        _gp6Frontier,
        const Province(
          id: 'oldWorld|minor1_p1',
          regionId: 'oldWorld',
          ownerId: _minor1,
        ),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 8,
      atWarWith: const [_gp6],
      invadable: const ['oldWorld|gp6_frontier', 'oldWorld|minor1_p1'],
      turnNumber: 60,
      expected: false,
      reason: 'minor-owned invadable province must break the GP-only focus',
    ),
    _Case(
      name: 'false when every invadable province is owned by a tribe (no GP)',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [
        ..._ow(_gp5, 8),
        const Province(
          id: 'oldWorld|tribe1_p1',
          regionId: 'oldWorld',
          ownerId: _tribe1,
        ),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      ow: 8,
      invadable: const ['oldWorld|tribe1_p1'],
      turnNumber: 60,
      expected: false,
      reason:
          'tribe-owned invadable provinces do not satisfy the GP-only check',
    ),
    _Case(
      name: 'true when below quota and every invadable province is owned by a '
          'Great Power (canonical seed-42 gp5/gp6 trap)',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [..._ow(_gp5, 9), _gp6Frontier],
      ow: 9,
      atWarWith: const [_gp6],
      invadable: const ['oldWorld|gp6_frontier'],
      turnNumber: 60,
      expected: true,
    ),
    _Case(
      name: 'true at zero OW provinces with an all-GP invadable list '
          '(lower bound)',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: const [_gp6Frontier],
      ow: 0,
      atWarWith: const [_gp6],
      invadable: const ['oldWorld|gp6_frontier'],
      turnNumber: 60,
      expected: true,
      reason: 'no non-zero OW floor — only the quota ceiling matters',
    ),
    _Case(
      name: 'true just below the observer OW quota with an all-GP invadable '
          'list (quota - 1 boundary)',
      players: _gp5gp6,
      playerId: _gp5,
      owProvinces: [
        ..._ow(_gp5, kObserverConquestMinOwProvincesPerGp - 1),
        _gp6Frontier,
      ],
      ow: kObserverConquestMinOwProvincesPerGp - 1,
      atWarWith: const [_gp6],
      invadable: const ['oldWorld|gp6_frontier'],
      turnNumber: 60,
      expected: true,
      reason: 'one province below quota must still trip the predicate',
    ),
  ]);

  // --- canPivotFromSoleGpWarAfterPeace (gp1/gp2 roster, minor pivot scan). ---
  _runPredicate('canPivotFromSoleGpWarAfterPeace (truth table)',
      canPivotFromSoleGpWarAfterPeace, <_Case>[
    _Case(
      name: 'quota-met short-circuit returns true even with no minor pivot',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: _ow(_gp1, kObserverConquestMinOwProvincesPerGp, start: 1),
      ow: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const [_gp2],
      expected: true,
      reason:
          'A GP at the observer OW quota satisfies the leading short '
          'circuit regardless of pivot availability; '
          '`unwinnableSoleGpFrontierPeaceTarget` can then still consider '
          'a sole outgunned-GP peace target. A regression that dropped '
          'this short-circuit would refuse the SPEC-authorized peace '
          'pivot whenever quota-met GPs hold a sole foe without any '
          'remaining minor or invadable-minor frontier.',
    ),
    _Case(
      name: 'quota-exceeded with no minor pivot still returns true',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: _ow(_gp1, kObserverConquestMinOwProvincesPerGp + 5, start: 1),
      ow: kObserverConquestMinOwProvincesPerGp + 5,
      atWarWith: const [_gp2],
      expected: true,
      reason:
          'The quota-met branch is a `>=` short circuit; OW totals '
          'above quota must keep returning true so consolidate-gains '
          'callers see the same pivot availability.',
    ),
    _Case(
      name: 'below quota with an OW-owning uninvaded minor returns true',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: [
        ..._ow(_gp1, 8, start: 1),
        const Province(
          id: 'oldWorld|minor1_a',
          regionId: 'oldWorld',
          ownerId: _minor1,
        ),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 8,
      atWarWith: const [_gp2],
      invadable: const ['oldWorld|minor1_a'],
      expected: true,
      reason:
          'An OW minor on the map provides the SPEC-authorized minor '
          'pivot when the GP peaces its sole GP foe. A regression '
          'that collapsed the OW `minorsOnMap` scan would strand '
          'below-quota GPs in stalemated sole-GP wars (Refs #2509 '
          'turn-100 verify exit code 5).',
    ),
    _Case(
      name: 'OW minor already in atWarWith still counts as a pivot '
          '(no at-war filter)',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: [
        ..._ow(_gp1, 8, start: 1),
        const Province(
          id: 'oldWorld|minor1_a',
          regionId: 'oldWorld',
          ownerId: _minor1,
        ),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 8,
      atWarWith: const [_gp2, _minor1],
      invadable: const ['oldWorld|minor1_a'],
      expected: true,
      reason:
          'The function is a pivot-availability check; whether the '
          'minor is currently in the at-war set is the higher-level '
          "collector's concern. Pinning this contract keeps that "
          'separation explicit.',
    ),
    _Case(
      name: 'below quota with NW-only minor in invadable list returns true (B3)',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: _ow(_gp1, 8, start: 1),
      nwProvinces: const [
        Province(
          id: 'newWorld|minor1_a',
          regionId: 'newWorld',
          ownerId: _minor1,
        ),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 8,
      atWarWith: const [_gp2],
      invadable: const ['newWorld|minor1_a'],
      expected: true,
      reason:
          'When no OW minor exists, an invadable-list province with '
          'a minor owner still satisfies the pivot check via the '
          'trailing `any`. A regression that collapsed this scan '
          'would refuse peace whenever the only pivot is an NW '
          'colonial minor frontier.',
    ),
    _Case(
      name: 'below quota with GP-only invadable frontier and no minors returns '
          'false',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: [
        ..._ow(_gp1, 8, start: 1),
        ..._ow(_gp2, 3, start: 1),
      ],
      ow: 8,
      atWarWith: const [_gp2],
      invadable: const ['oldWorld|gp2_1', 'oldWorld|gp2_2'],
      expected: false,
      reason:
          'No minor anywhere and a GP-only invadable frontier means '
          'peacing the sole GP foe leaves no SPEC-legal pivot target. '
          'A regression that defaulted to true here would peace the '
          "GP's only opponent and deadlock the EXPAND strategy "
          '(Refs #2509 § Observer goal phases (Full AI), EXPAND).',
    ),
    _Case(
      name: 'below quota with empty invadable list and no minors returns false',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: _ow(_gp1, 8, start: 1),
      ow: 8,
      atWarWith: const [_gp2],
      expected: false,
      reason:
          'An empty invadable list combined with no OW minor on the '
          'map provides no pivot; the trailing `any` is false and '
          'the predicate must return false. A regression that '
          'short-circuited the empty-invadable branch to true would '
          'spuriously authorize peace pivots when no pivot exists.',
    ),
    _Case(
      name: 'just below quota with no minor and no invadable minor returns '
          'false',
      players: _gp1gp2,
      playerId: _gp1,
      owProvinces: _ow(_gp1, kObserverConquestMinOwProvincesPerGp - 1, start: 1),
      ow: kObserverConquestMinOwProvincesPerGp - 1,
      atWarWith: const [_gp2],
      expected: false,
      reason:
          'The quota comparison is `>=`, so ownOw = quota - 1 must '
          'NOT short-circuit to true. With no minor pivot, the '
          'predicate must reach the trailing `return false` exit.',
    ),
  ]);

  // --- hasUninvadedOldWorldMinor (single-GP roster, minor OW scan). ---
  _runPredicate('hasUninvadedOldWorldMinor (truth table)',
      hasUninvadedOldWorldMinor, <_Case>[
    _Case(
      name: 'empty minor roster -> false',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
      ],
      ow: 0,
      turnNumber: 50,
      expected: false,
      reason:
          'No minor nations on the map means the loop body never runs '
          'and the trailing `return false` is the only reachable exit. '
          'A regression that defaulted to true on an empty roster would '
          'incorrectly trigger the EXPAND minor-first peace pivot for '
          'every below-quota GP, peacing every live GP front and '
          'stalling the turn-100 conquest gate.',
    ),
    _Case(
      name: 'uninvaded minor that owns no OW province -> false',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 0,
      turnNumber: 50,
      expected: false,
      reason:
          'A minor that is not in `atWarWith` but owns no OW province '
          'cannot be the target of an EXPAND minor-first declare-war. '
          'The province-scan `any` is false, the loop completes, and '
          'the predicate falls through to `return false`. A regression '
          'that returned true on roster presence alone (without OW '
          'ownership) would trigger minor-first with no real '
          'declare-war target, peacing the wrong GP fronts.',
    ),
    _Case(
      name: 'uninvaded minor owns only NW province -> false',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
      ],
      nwProvinces: const [
        Province(id: 'newWorld|m1_a', regionId: 'newWorld', ownerId: _minor1),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 0,
      turnNumber: 50,
      expected: false,
      reason:
          'NW minor holdings do not satisfy the EXPAND minor-first '
          'predicate -- the function iterates `oldWorld.provinces` '
          'only. A regression that scanned both regions would trigger '
          'EXPAND minor-first based on colonial holdings and peace '
          'live OW GP fronts that the minor-first rule was never '
          'meant to gate.',
    ),
    _Case(
      name: 'uninvaded minor owns at least one OW province -> true',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 0,
      turnNumber: 50,
      expected: true,
      reason:
          'Single uninvaded minor with one OW province satisfies the '
          'EXPAND minor-first precondition (SPEC § EXPAND "exit every '
          'GP front while uninvaded OW minors remain"). This is the '
          'canonical positive path: the first iteration short-circuits '
          'via the `any` predicate, the function returns true without '
          'inspecting the rest of the OW province list.',
    ),
    _Case(
      name: 'only candidate minor is in atWarWith -> false (skip branch)',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      ow: 0,
      atWarWith: const [_minor1],
      turnNumber: 50,
      expected: false,
      reason:
          'An at-war minor is "invaded" for the purpose of minor-first '
          'and must be skipped via `continue`. Even though the minor '
          'still owns OW (`oldWorld|m1_a`), the `atWarWith.contains` '
          'guard runs **before** the province `any` scan, so the '
          'province ownership never participates in the decision. A '
          'regression that inverted the guard would re-engage '
          'minor-first on every already-declared minor war and peace '
          'live GP fronts at quota.',
    ),
    _Case(
      name: 'mixed minors: first at-war (skipped), second uninvaded + OW -> '
          'true',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
      ],
      minorNations: const [
        MinorNation(id: _minor1, displayName: 'M1'),
        MinorNation(id: _minor2, displayName: 'M2'),
      ],
      ow: 0,
      atWarWith: const [_minor1],
      turnNumber: 50,
      expected: true,
      reason:
          'The first minor (`minor1`) is in `atWarWith` and must be '
          '`continue`d; the second minor (`minor2`) is uninvaded and '
          'still owns `oldWorld|m2_a`, so the second iteration\'s '
          '`any` predicate returns true. A regression that returned '
          'after the first `continue` (or otherwise short-circuited '
          'on the first skipped minor) would mis-report no '
          'minor-first target despite a clear declare-war candidate.',
    ),
    _Case(
      name: 'mixed minors: first uninvaded no-OW, second uninvaded + OW -> true',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
      ],
      minorNations: const [
        MinorNation(id: _minor1, displayName: 'M1'),
        MinorNation(id: _minor2, displayName: 'M2'),
      ],
      ow: 0,
      turnNumber: 50,
      expected: true,
      reason:
          'The first minor (`minor1`) is uninvaded but owns no OW '
          'province; the inner `any` returns false and the outer '
          'loop must keep iterating, not return false early. The '
          'second minor (`minor2`) supplies the positive `any`. A '
          'regression that returned false after the first failed '
          'inner scan would miss every minor-first target whenever '
          'the no-OW minor was iterated first.',
    ),
    _Case(
      name: 'every minor is at-war -> false',
      players: _gp1only,
      playerId: _gp1,
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
      ],
      minorNations: const [
        MinorNation(id: _minor1, displayName: 'M1'),
        MinorNation(id: _minor2, displayName: 'M2'),
      ],
      ow: 0,
      atWarWith: const [_minor1, _minor2],
      turnNumber: 50,
      expected: false,
      reason:
          'No uninvaded minor remains: every iteration `continue`s on '
          'the `atWarWith` check, and the trailing `return false` is '
          'the only reachable exit. A regression that ignored the '
          'at-war guard would falsely re-engage EXPAND minor-first '
          'on a roster that has no minor declare-war target left, '
          'peacing live GP fronts in the late EXPAND window.',
    ),
  ]);

  // Repeated-call determinism guards retained verbatim from the source suites
  // (must-have #7). These are the only assertions that are not a single
  // `(game, snapshot) -> bool` row.
  group('peace-predicate determinism guards', () {
    test(
      'canPivotFromSoleGpWarAfterPeace: identical inputs produce identical '
      'outputs (must-have #7)',
      () {
        const c = _Case(
          name: 'determinism',
          players: _gp1gp2,
          playerId: _gp1,
          owProvinces: [
            Province(id: 'oldWorld|gp1_1', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_2', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_3', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_4', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_5', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_6', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_7', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|gp1_8', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|minor1_a', regionId: 'oldWorld', ownerId: _minor1),
          ],
          minorNations: [MinorNation(id: _minor1, displayName: 'M1')],
          ow: 8,
          atWarWith: [_gp2],
          invadable: ['oldWorld|minor1_a'],
          expected: true,
        );
        final game = _buildGame(c);
        final snapshot = _snapshot(c);
        final first =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        final second =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        final third =
            canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot);
        expect(first, isTrue);
        expect(second, first);
        expect(third, first);
      },
    );

    test(
      'hasUninvadedOldWorldMinor: identical inputs produce identical outputs',
      () {
        const c = _Case(
          name: 'determinism',
          players: _gp1only,
          playerId: _gp1,
          owProvinces: [
            Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
            Province(id: 'oldWorld|m2_a', regionId: 'oldWorld', ownerId: _minor2),
          ],
          minorNations: [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
          ow: 0,
          atWarWith: [_minor1],
          turnNumber: 50,
          expected: true,
        );
        final game = _buildGame(c);
        final snapshot = _snapshot(c);
        final first = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
        final second = hasUninvadedOldWorldMinor(game: game, snapshot: snapshot);
        expect(second, first);
        expect(
          first,
          isTrue,
          reason:
              'Sanity-check the determinism fixture exercises the positive '
              'branch (so a regression that always returned false would '
              'still fail this group, not just silently match itself).',
        );
      },
    );
  });
}
