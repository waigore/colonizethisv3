// Table-driven matrix consolidation of the EXPAND `(game, snapshot) ->
// List<String>` peace-target decider pins (Refs #3749 branch-pin
// consolidation, continuation of the function-unit predicate matrix in
// `expand_phase_planner_below_quota_peace_predicate_matrix_test.dart`).
//
// This single file replaces four former per-decider `*_branches_test.dart`
// suites that each pinned one EXPAND peace-target decider from
// `expand_phase_planner.dart` with one `test(...)` per branch:
//
//   - `expand_phase_planner_critical_ow_hold_branches_test.dart`
//   - `expand_phase_planner_quota_met_below_quota_at_war_peace_branches_test.dart`
//   - `expand_phase_planner_default_start_gp_peace_branches_test.dart`
//   - `expand_phase_planner_quota_met_futile_below_quota_gp_peace_branches_test.dart`
//
// All four deciders share the exact signature
// `({required Game game, required AIWorldSnapshot snapshot}) -> List<String>`,
// so each former branch case becomes one matrix row here with byte-equivalent
// fixture inputs (Old World province ownership, player/minor/tribe roster, the
// planning GP id, own OW count, `atWarWith`, and the invadable-OW frontier)
// and the same verbatim expected target list + regression `reason`. Coverage
// is preserved 1:1 — every former assertion has a corresponding row — while the
// per-file scaffolding collapses into one shared `_buildGame` / `_snapshot`
// harness and four table-driven loops. See each original suite's history for
// the full per-branch rationale; the `reason` text on each row carries the
// regression it guards.
//
// The remaining sibling `stalledBelowQuotaGpLeadPeaceTargets` decider uses a
// distinct `DiplomacyRelation`-backed fixture builder (it reads at-war
// relations + invadable owners through `isOldWorldGpOnlyInvadableFrontier`),
// so it is intentionally left to a follow-up slice rather than forced into
// this roster/ownership harness.
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI) — EXPAND
// diplomacy targeting (critical-OW-hold survival peace, quota-met
// below-quota futile-bullying peace, and the default-start GP peace pivot;
// Refs #2509).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

/// Default 4-GP roster shared by the `defaultStartGpPeaceTargets` and
/// `quotaMetFutileBelowQuotaGpPeaceTargets` rows (those source suites relied on
/// the builder default rather than passing players per case).
const List<Player> _defaultGpRoster = <Player>[
  Player(id: _gp1, displayName: 'GP1', isHuman: false),
  Player(id: _gp2, displayName: 'GP2', isHuman: false),
  Player(id: _gp3, displayName: 'GP3', isHuman: false),
  Player(id: _gp4, displayName: 'GP4', isHuman: false),
];

/// `count` Old World provinces owned by [ownerId], ids `oldWorld|<owner>_<i>`.
/// Only province *ownership* is read by these deciders (`provinceCountOwnedBy`
/// / `getProvinceOwnerMap`), so the synthetic ids are arbitrary except where a
/// row's [_Case.invadable] list references a specific id (those are added as
/// explicit provinces in the row).
List<Province> _owned(String ownerId, int count) => <Province>[
  for (var i = 0; i < count; i++)
    Province(id: 'oldWorld|${ownerId}_$i', regionId: 'oldWorld', ownerId: ownerId),
];

typedef _PeaceTargetsFn = List<String> Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
class _Case {
  const _Case({
    required this.name,
    required this.owProvinces,
    required this.players,
    required this.playerId,
    required this.ownOw,
    required this.atWarWith,
    this.expected,
    this.invadable = const <String>[],
    this.minorNations = const <MinorNation>[],
    this.tribes = const <Tribe>[],
    this.reason,
  });

  final String name;
  final List<Province> owProvinces;
  final List<Player> players;
  final String playerId;
  final int ownOw;
  final List<String> atWarWith;

  /// Expected target list; `null` asserts `isEmpty` (matches the source suites'
  /// `isEmpty` matcher exactly).
  final List<String>? expected;
  final List<String> invadable;
  final List<MinorNation> minorNations;
  final List<Tribe> tribes;
  final String? reason;
}

Game _buildGame(_Case c) => Game(
  id: 'g-expand-peace-target-matrix',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
    oldWorld: RegionData(provinces: c.owProvinces),
    newWorld: const RegionData(),
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
    oldWorldProvincesOwned: c.ownOw,
    invadableProvinceIdsSorted: c.invadable,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

void _runDecider(String label, _PeaceTargetsFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        final result = fn(game: _buildGame(c), snapshot: _snapshot(c));
        if (c.expected == null) {
          expect(result, isEmpty, reason: c.reason);
        } else {
          expect(result, c.expected, reason: c.reason);
        }
      });
    }
  });
}

void main() {
  // --- criticalOwHoldPeaceTargets (focus roster, count-map provinces). ---
  _runDecider('criticalOwHoldPeaceTargets (truth table)',
      criticalOwHoldPeaceTargets, <_Case>[
    _Case(
      name: 'returns const [] when atWarWith contains only a minor',
      owProvinces: _owned('focus', 5),
      players: const [Player(id: 'focus', displayName: 'Focus', isHuman: false)],
      minorNations: const [MinorNation(id: 'minor_a', displayName: 'M')],
      playerId: 'focus',
      ownOw: 5,
      atWarWith: const ['minor_a'],
      reason:
          'Minors are not part of the GP-only critical-hold peace family. '
          'Even with `ownOw == 5` well inside the defend threshold the helper '
          'must short-circuit when `game.playerById(...) != null` filters the '
          'at-war list to empty.',
    ),
    _Case(
      name: 'returns const [] above the defend threshold but below quota '
          '(own == kFewOldWorldProvincesDefendThreshold + 1)',
      owProvinces: [..._owned('focus', 7), ..._owned('gp_enemy', 6)],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kFewOldWorldProvincesDefendThreshold + 1,
      atWarWith: const ['gp_enemy'],
      reason:
          'Above kFewOldWorldProvincesDefendThreshold (6) the helper must NOT '
          'fire even while still below the observer quota. A regression that '
          'flipped `<=` to `<` on the threshold check would widen the band to '
          'OW 7.',
    ),
    _Case(
      name: 'returns const [] at the observer quota '
          '(own == kObserverConquestMinOwProvincesPerGp)',
      owProvinces: [..._owned('focus', 10), ..._owned('gp_enemy', 6)],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const ['gp_enemy'],
      reason:
          'At kObserverConquestMinOwProvincesPerGp (10) the GP has met the '
          'observer quota and `isBelowObserverConquestQuota` is false. A '
          'regression that flipped `<` to `<=` would engage critical-hold '
          'peace exactly when the observer turn-100 gate clears.',
    ),
    _Case(
      name: 'fires toward a sole GP enemy strictly below the defend threshold '
          '(own == kFewOldWorldProvincesDefendThreshold - 1)',
      owProvinces: [..._owned('focus', 5), ..._owned('gp_enemy', 10)],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_enemy', displayName: 'E', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kFewOldWorldProvincesDefendThreshold - 1,
      atWarWith: const ['gp_enemy'],
      expected: const ['gp_enemy'],
      reason:
          'Strictly below kFewOldWorldProvincesDefendThreshold (6) with a sole '
          'GP enemy at war the helper must surface that enemy so the survival-'
          'peace family fires (pins the interior `<` branch of the band).',
    ),
    _Case(
      name: 'returns ascending factionId order when atWarWith lists GP enemies '
          'in descending lexical order',
      owProvinces: [
        ..._owned('focus', 6),
        ..._owned('gp_a', 6),
        ..._owned('gp_z', 6),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_a', displayName: 'A', isHuman: false),
        Player(id: 'gp_z', displayName: 'Z', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kFewOldWorldProvincesDefendThreshold,
      atWarWith: const ['gp_z', 'gp_a'],
      expected: const ['gp_a', 'gp_z'],
      reason:
          'The returned list is `..sort()`-ed so downstream offer-peace scoring '
          'observes a stable order regardless of the iteration order of '
          '`snapshot.threats.atWarWith` (Refs #2509 must-have #7).',
    ),
  ]);

  // --- quotaMetBelowQuotaAtWarPeaceTargets (focus roster, count-map). ---
  _runDecider('quotaMetBelowQuotaAtWarPeaceTargets (truth table)',
      quotaMetBelowQuotaAtWarPeaceTargets, <_Case>[
    _Case(
      name: 'returns const [] at own == quota - 1 even with two below-quota '
          'GP enemies at war',
      owProvinces: [
        ..._owned('focus', kObserverConquestMinOwProvincesPerGp - 1),
        ..._owned('gp_low_a', 5),
        ..._owned('gp_low_b', 6),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_low_a', displayName: 'A', isHuman: false),
        Player(id: 'gp_low_b', displayName: 'B', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp - 1,
      atWarWith: const ['gp_low_a', 'gp_low_b'],
      reason:
          'Below the observer quota the helper must short-circuit before '
          'evaluating targets. A regression that flipped `<` to `<=` would '
          're-engage quota-met peace one province early.',
    ),
    _Case(
      name: 'returns the sole below-quota GP enemy at own == quota boundary',
      owProvinces: [
        ..._owned('focus', kObserverConquestMinOwProvincesPerGp),
        ..._owned('gp_low_a', 5),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_low_a', displayName: 'A', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const ['gp_low_a'],
      expected: const ['gp_low_a'],
      reason:
          'Exactly at kObserverConquestMinOwProvincesPerGp (10 OW today) the '
          'helper must fire toward a below-quota GP enemy. A regression that '
          'pushed the threshold to `> quota` would delay the exit by one '
          'province.',
    ),
    _Case(
      name: 'filters out at-war minors (only GP targets are returned)',
      owProvinces: [
        ..._owned('focus', kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned('minor_low', 3),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'minor_low', displayName: 'M')],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const ['minor_low'],
      reason:
          'Minors and tribes are not in the GP-vs-GP futile-bullying war family '
          'this helper exits. A regression that dropped the '
          '`game.playerById(...) != null` guard would sweep a minor war into '
          'the GP peace list.',
    ),
    _Case(
      name: 'filters out a GP target whose own holdings are at observer quota',
      owProvinces: [
        ..._owned('focus', kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned('gp_at_quota', kObserverConquestMinOwProvincesPerGp),
        ..._owned('gp_low', kObserverConquestMinOwProvincesPerGp - 1),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_at_quota', displayName: 'Q', isHuman: false),
        Player(id: 'gp_low', displayName: 'L', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const ['gp_at_quota', 'gp_low'],
      expected: const ['gp_low'],
      reason:
          'A GP exactly at kObserverConquestMinOwProvincesPerGp is no longer '
          'below the quota and must not appear in the futile-bullying peace '
          'list. A regression that flipped `<` to `<=` on the target side '
          'would sweep in peers who already cleared their quota.',
    ),
    _Case(
      name: 'returns ascending factionId order regardless of at-war list order',
      owProvinces: [
        ..._owned('focus', kObserverConquestMinOwProvincesPerGp + 1),
        ..._owned('gp_a', 4),
        ..._owned('gp_b', 5),
      ],
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
        Player(id: 'gp_a', displayName: 'A', isHuman: false),
        Player(id: 'gp_b', displayName: 'B', isHuman: false),
      ],
      playerId: 'focus',
      ownOw: kObserverConquestMinOwProvincesPerGp + 1,
      atWarWith: const ['gp_b', 'gp_a'],
      expected: const ['gp_a', 'gp_b'],
      reason:
          'Multi-target results must be sorted ascending so downstream '
          'offer-peace scoring and trace logs are independent of the iteration '
          'order of snapshot.threats.atWarWith.',
    ),
  ]);

  // --- defaultStartGpPeaceTargets (default 4-GP + tribe1 roster, gp1). ---
  _runDecider('defaultStartGpPeaceTargets (truth table)',
      defaultStartGpPeaceTargets, <_Case>[
    _Case(
      name: 'not below quota -> empty (OW = quota)',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const [_gp2],
      invadable: const ['oldWorld|gp2_a'],
      reason:
          'At quota the EXPAND default-start pivot is no longer in scope; the '
          'helper must return empty so the COLONIAL peace rules govern '
          'post-quota wars.',
    ),
    _Case(
      name: 'ownOw above ceiling with no uninvaded minor -> empty',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kStalledOldWorldProvinceThreshold,
      atWarWith: const [_gp2],
      invadable: const ['oldWorld|gp2_a'],
      reason:
          'Without an uninvaded minor on the map the ceiling is 8 OW, so OW=9 '
          'must NOT engage the pivot — there is no minor front to pivot to.',
    ),
    _Case(
      name: 'ownOw at ceiling WITH uninvaded minor -> non-blocker GPs returned',
      owProvinces: const [
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      playerId: _gp1,
      ownOw: kStalledOldWorldProvinceThreshold,
      atWarWith: const [_gp2],
      invadable: const ['oldWorld|m1_a'],
      expected: const [_gp2],
      reason:
          'With an uninvaded minor on the map the ceiling extends to 9 OW and '
          'the lone non-blocker GP must be returned; the only invadable OW is '
          'minor-owned so the frontier is not GP-only and the blocker is null.',
    ),
    _Case(
      name: '!gpOnlyFrontier -> blocker null -> all GPs returned',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp + 1,
      atWarWith: const [_gp2, _gp3],
      invadable: const ['oldWorld|gp2_a', 'oldWorld|m1_a'],
      expected: const [_gp2, _gp3],
      reason:
          'When the frontier mixes GP and minor owners no GP qualifies as the '
          'blocker (the minor pivot is available), so every at-war GP is peaced '
          'in ascending factionId order.',
    ),
    _Case(
      name: 'gpOnlyFrontier with multiple GPs at war -> only blocker excluded',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp + 1,
      atWarWith: const [_gp2, _gp3],
      invadable: const ['oldWorld|gp2_a'],
      expected: const [_gp3],
      reason:
          'On a GP-only frontier the blocker (gp2) holds the only winnable OW '
          'front and must be preserved; remaining GP wars (gp3) are peaced.',
    ),
    _Case(
      name: 'non-GP factions filtered out of returned list',
      owProvinces: const [
        Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
      atWarWith: const [_gp2, _tribe1],
      invadable: const ['oldWorld|m1_a'],
      expected: const [_gp2],
      reason:
          'Tribes and minors are not Great Powers; the helper is the GP arm of '
          'the EXPAND default-start peace pivot and must pass non-GP factions '
          'through to their own sibling helpers.',
    ),
    _Case(
      name: 'empty atWarWith -> empty',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
      atWarWith: const [],
      invadable: const ['oldWorld|gp2_a'],
      reason:
          'Empty `atWarWith` means there is nothing to peace, even at default '
          'start size — the helper must not synthesize new peace targets out '
          'of the player roster.',
    ),
    _Case(
      name: 'atWarWith returned in ascending factionId order',
      owProvinces: const [
        Province(id: 'oldWorld|gp1_a', regionId: 'oldWorld', ownerId: _gp1),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
      atWarWith: const [_gp4, _gp2, _gp3],
      expected: const [_gp2, _gp3, _gp4],
      reason:
          'The helper must sort returned faction ids ascending so downstream '
          'order generation is deterministic for a fixed seed.',
    ),
    _Case(
      name: 'identical inputs produce identical peace target list',
      owProvinces: const [
        Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverDefaultStartOldWorldProvincesPerGp,
      atWarWith: const [_gp2, _gp3, _gp4],
      invadable: const ['oldWorld|gp2_a'],
      expected: const [_gp3, _gp4],
      reason:
          'On a GP-only frontier (gp2 owns the sole invadable OW) the blocker '
          'gp2 is excluded; the remaining GP wars resolve to the deterministic '
          'ascending list.',
    ),
  ]);

  // --- quotaMetFutileBelowQuotaGpPeaceTargets (default 4-GP + minor1 + ---
  // --- tribe1 roster, gp1, explicit invadable frontier). ---
  _runDecider('quotaMetFutileBelowQuotaGpPeaceTargets (truth table)',
      quotaMetFutileBelowQuotaGpPeaceTargets, <_Case>[
    _Case(
      name: 'returns [] when own OW is one below the observer quota '
          '(isBelowObserverConquestQuota early guard)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp - 1),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp - 1,
      atWarWith: const [_gp3],
      invadable: const ['oldWorld|inv1'],
      reason:
          'The futile-below-quota peace helper is reserved for quota-met GPs; '
          'flipping `<` to `<=` in `isBelowObserverConquestQuota` would regress '
          'this early guard and double-emit peace from two helpers.',
    ),
    _Case(
      name: 'returns [] when no invadable OW provinces remain '
          '(invadableProvinceIdsSorted.isEmpty early guard)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp3, 8),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_gp3],
      reason:
          'No invadable OW frontier means there is nothing this helper must '
          'defend by keeping a war active; the consolidate / quota-met helpers '
          'own the peace decision.',
    ),
    _Case(
      name: 'skips non-GP factions in atWarWith (minors / tribes filtered)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_minor1, _tribe1, _gp3],
      invadable: const ['oldWorld|inv1'],
      expected: const [_gp3],
      reason:
          'Minors and tribes must be filtered by `game.playerById` even when '
          'they appear in `atWarWith`; only Great Powers surface as targets.',
    ),
    _Case(
      name: 'skips at-war enemy GPs that have met the observer quota',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp2, kObserverConquestMinOwProvincesPerGp),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_gp2, _gp3],
      invadable: const ['oldWorld|inv1'],
      expected: const [_gp3],
      reason:
          'Quota-met enemy GPs are not "futile below quota"; the per-enemy '
          'quota check must stay strictly below the threshold (matches '
          '`isBelowObserverConquestQuota`).',
    ),
    _Case(
      name: 'skips at-war enemy GPs that own one of the invadable OW provinces',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp2, 7),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|gp2_inv', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_gp2, _gp3],
      invadable: const ['oldWorld|gp2_inv'],
      expected: const [_gp3],
      reason:
          'Peacing an enemy GP that owns the remaining invadable OW frontier '
          'forfeits the conquest path the quota-met GP is still pursuing; gp2 '
          'must stay at war and only the futile gp3 front is peaced.',
    ),
    _Case(
      name: 'skips the primary invadable OW blocker (defensive backstop)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp2, 6),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|gp2_inv_a', regionId: 'oldWorld', ownerId: _gp2),
        const Province(id: 'oldWorld|gp2_inv_b', regionId: 'oldWorld', ownerId: _gp2),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_gp2, _gp3],
      invadable: const ['oldWorld|gp2_inv_a', 'oldWorld|gp2_inv_b'],
      expected: const [_gp3],
      reason:
          'gp2 is the primary invadable OW blocker; peacing it would lose the '
          'OW acquisition path. The defensive `factionId == blocker` clause '
          'guarantees blocker exclusion independently of the invadable-owning '
          'lookup.',
    ),
    _Case(
      name: 'returns multiple below-quota non-blocker enemy GPs sorted by '
          'factionId',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp2, 8),
        ..._owned(_gp3, 8),
        ..._owned(_gp4, 7),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_gp4, _gp2, _gp3],
      invadable: const ['oldWorld|inv1'],
      expected: const [_gp2, _gp3, _gp4],
      reason:
          'Must-have #7 (determinism): the returned list must be sorted by '
          'factionId ascending so a fixed seed yields identical merged orders.',
    ),
    _Case(
      name: 'filters an interleaved non-GP entry AND sorts the remaining '
          'eligible GPs (shared gpAtWarPeaceTargetsWhere skeleton)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ..._owned(_gp2, 8),
        ..._owned(_gp4, 7),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp + 2,
      atWarWith: const [_minor1, _gp4, _gp2],
      invadable: const ['oldWorld|inv1'],
      expected: const [_gp2, _gp4],
      reason:
          'After routing through gpAtWarPeaceTargetsWhere the helper must still '
          'drop the interleaved minor and return the eligible GPs in ascending '
          'factionId order — byte-identical to the inline loop it replaced.',
    ),
    _Case(
      name: 'enters main pass when own OW equals the observer quota '
          '(strict `<` boundary)',
      owProvinces: [
        ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp),
        ..._owned(_gp3, 8),
        const Province(id: 'oldWorld|inv1', regionId: 'oldWorld', ownerId: _minor1),
      ],
      players: _defaultGpRoster,
      minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      playerId: _gp1,
      ownOw: kObserverConquestMinOwProvincesPerGp,
      atWarWith: const [_gp3],
      invadable: const ['oldWorld|inv1'],
      expected: const [_gp3],
      reason:
          'The quota boundary `own == kObserverConquestMinOwProvincesPerGp` is '
          'the first turn a GP qualifies; flipping the comparison would delay '
          'the futile-below-quota peace pass by one quota tick.',
    ),
  ]);

  // Function-unit determinism + blocker-identity guards retained verbatim from
  // the source suites (the only assertions that are not a single
  // `(game, snapshot) -> targets` row).
  group('peace-target decider determinism / blocker-identity guards', () {
    test('defaultStartGpPeaceTargets is bit-identical on repeated calls', () {
      final game = _buildGame(
        const _Case(
          name: 'determinism',
          owProvinces: [
            Province(id: 'oldWorld|gp2_a', regionId: 'oldWorld', ownerId: _gp2),
          ],
          players: _defaultGpRoster,
          tribes: [Tribe(id: _tribe1, displayName: 'T1')],
          playerId: _gp1,
          ownOw: 7,
          atWarWith: [_gp2, _gp3, _gp4],
          invadable: ['oldWorld|gp2_a'],
        ),
      );
      final snapshot = _snapshot(
        const _Case(
          name: 'determinism',
          owProvinces: [],
          players: _defaultGpRoster,
          playerId: _gp1,
          ownOw: 7,
          atWarWith: [_gp2, _gp3, _gp4],
          invadable: ['oldWorld|gp2_a'],
        ),
      );
      final first = defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
      final second = defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
      expect(second, first);
      expect(first, const [_gp3, _gp4]);
    });

    test('primaryInvadableOldWorldGpBlocker resolves to the plurality owner '
        '(gp2) for the blocker-equality fixture', () {
      final c = _Case(
        name: 'blocker sanity',
        owProvinces: [
          ..._owned(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
          ..._owned(_gp2, 6),
          ..._owned(_gp3, 8),
          const Province(id: 'oldWorld|gp2_inv_a', regionId: 'oldWorld', ownerId: _gp2),
          const Province(id: 'oldWorld|gp2_inv_b', regionId: 'oldWorld', ownerId: _gp2),
        ],
        players: _defaultGpRoster,
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        playerId: _gp1,
        ownOw: kObserverConquestMinOwProvincesPerGp + 2,
        atWarWith: const [_gp2, _gp3],
        invadable: const ['oldWorld|gp2_inv_a', 'oldWorld|gp2_inv_b'],
      );
      expect(
        primaryInvadableOldWorldGpBlocker(
          game: _buildGame(c),
          snapshot: _snapshot(c),
        ),
        _gp2,
        reason:
            'Fixture sanity: gp2 owns the plurality of invadable OW so the '
            'blocker resolves to gp2 — the blocker-equality skip arm in '
            '`quotaMetFutileBelowQuotaGpPeaceTargets` must exclude gp2 even if '
            'the invadable-owning skip is bypassed by a future refactor.',
      );
    });
  });
}
