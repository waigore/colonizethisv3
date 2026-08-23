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

typedef _PeaceTargetsFn =
    List<String> Function({
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

void registerExpandPeaceTargetDeciderHoldQuotaGuardCases() {
  _runDecider('criticalOwHoldPeaceTargets (truth table)', criticalOwHoldPeaceTargets, <
    _Case
  >[
    _Case(
      name: 'returns const [] when atWarWith contains only a minor',
      owProvinces: oldWorldProvincesForExpandPeaceMatrix('focus', 5),
      players: const [
        Player(id: 'focus', displayName: 'Focus', isHuman: false),
      ],
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
      name:
          'returns const [] above the defend threshold but below quota '
          '(own == kFewOldWorldProvincesDefendThreshold + 1)',
      owProvinces: [
        ...oldWorldProvincesForExpandPeaceMatrix('focus', 7),
        ...oldWorldProvincesForExpandPeaceMatrix('gp_enemy', 6),
      ],
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
      name:
          'returns const [] at the observer quota '
          '(own == kObserverConquestMinOwProvincesPerGp)',
      owProvinces: [
        ...oldWorldProvincesForExpandPeaceMatrix('focus', 10),
        ...oldWorldProvincesForExpandPeaceMatrix('gp_enemy', 6),
      ],
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
      name:
          'fires toward a sole GP enemy strictly below the defend threshold '
          '(own == kFewOldWorldProvincesDefendThreshold - 1)',
      owProvinces: [
        ...oldWorldProvincesForExpandPeaceMatrix('focus', 5),
        ...oldWorldProvincesForExpandPeaceMatrix('gp_enemy', 10),
      ],
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
      name:
          'returns ascending factionId order when atWarWith lists GP enemies '
          'in descending lexical order',
      owProvinces: [
        ...oldWorldProvincesForExpandPeaceMatrix('focus', 6),
        ...oldWorldProvincesForExpandPeaceMatrix('gp_a', 6),
        ...oldWorldProvincesForExpandPeaceMatrix('gp_z', 6),
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
}
