// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// ignore_for_file: unused_element, unused_element_parameter

// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

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

void _runDecider(String label, _PeaceTargetsFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        final result = fn(
          game: buildExpandPeaceMatrixGame(
            owProvinces: c.owProvinces,
            players: c.players,
            minorNations: c.minorNations,
            tribes: c.tribes,
            gameId: 'g-expand-peace-target-matrix',
          ),
          snapshot: buildExpandPeaceMatrixSnapshot(
            playerId: c.playerId,
            atWarWith: c.atWarWith,
            oldWorldProvincesOwned: c.ownOw,
            invadableProvinceIdsSorted: c.invadable,
          ),
        );
        if (c.expected == null) {
          expect(result, isEmpty, reason: c.reason);
        } else {
          expect(result, c.expected, reason: c.reason);
        }
      });
    }
  });
}

void registerExpandPeaceTargetDeciderStartCases() {
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp - 1),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp2, kObserverConquestMinOwProvincesPerGp),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp2, 7),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp2, 6),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp2, 8),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp4, 7),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp + 2),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp2, 8),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp4, 7),
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
        ...oldWorldProvincesForExpandPeaceMatrix(_gp1, kObserverConquestMinOwProvincesPerGp),
        ...oldWorldProvincesForExpandPeaceMatrix(_gp3, 8),
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
}
