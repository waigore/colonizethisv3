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

void registerExpandPeaceTargetDeciderHoldQuotaFireCases() {
  _runDecider(
    'quotaMetBelowQuotaAtWarPeaceTargets (truth table)',
    quotaMetBelowQuotaAtWarPeaceTargets,
    <_Case>[
      _Case(
        name:
            'returns const [] at own == quota - 1 even with two below-quota '
            'GP enemies at war',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            'focus',
            kObserverConquestMinOwProvincesPerGp - 1,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix('gp_low_a', 5),
          ...oldWorldProvincesForExpandPeaceMatrix('gp_low_b', 6),
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
          ...oldWorldProvincesForExpandPeaceMatrix(
            'focus',
            kObserverConquestMinOwProvincesPerGp,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix('gp_low_a', 5),
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
          ...oldWorldProvincesForExpandPeaceMatrix(
            'focus',
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix('minor_low', 3),
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
        name:
            'filters out a GP target whose own holdings are at observer quota',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            'focus',
            kObserverConquestMinOwProvincesPerGp + 2,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(
            'gp_at_quota',
            kObserverConquestMinOwProvincesPerGp,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(
            'gp_low',
            kObserverConquestMinOwProvincesPerGp - 1,
          ),
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
        name:
            'returns ascending factionId order regardless of at-war list order',
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            'focus',
            kObserverConquestMinOwProvincesPerGp + 1,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix('gp_a', 4),
          ...oldWorldProvincesForExpandPeaceMatrix('gp_b', 5),
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
    ],
  );

  // --- defaultStartGpPeaceTargets (default 4-GP + tribe1 roster, gp1). ---
}
