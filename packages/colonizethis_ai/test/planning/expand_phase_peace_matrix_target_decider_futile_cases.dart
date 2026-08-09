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


void registerExpandPeaceTargetDeciderFutileCases() {
  group('peace-target decider determinism / blocker-identity guards', () {
    test('defaultStartGpPeaceTargets is bit-identical on repeated calls', () {
      const c = _Case(
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
      );
      final game = buildExpandPeaceMatrixGame(
        owProvinces: c.owProvinces,
        players: c.players,
        tribes: c.tribes,
        gameId: 'g-expand-peace-target-matrix',
      );
      final snapshot = buildExpandPeaceMatrixSnapshot(
        playerId: c.playerId,
        atWarWith: c.atWarWith,
        oldWorldProvincesOwned: c.ownOw,
        invadableProvinceIdsSorted: c.invadable,
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
      );
      expect(
        primaryInvadableOldWorldGpBlocker(
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
