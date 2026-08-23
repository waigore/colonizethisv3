// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

// ignore_for_file: unused_element, unused_element_parameter

// EXPAND peace matrix case module (Refs #3749 / #3941).
// Registered from `expand_phase_peace_matrix_test.dart` — the single contract
// file for all four former `expand_phase_planner_*_peace_*_matrix_test.dart`
// shards. Row coverage is preserved 1:1.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String kExpandPeaceMatrixGp1 = 'gp1';
const String kExpandPeaceMatrixGp2 = 'gp2';
const String kExpandPeaceMatrixGp3 = 'gp3';
const String kExpandPeaceMatrixGp4 = 'gp4';
const String kExpandPeaceMatrixMinor1 = 'minor1';
const String kExpandPeaceMatrixTribe1 = 'tribe1';

/// Default 4-GP roster shared by the `defaultStartGpPeaceTargets` and
/// `quotaMetFutileBelowQuotaGpPeaceTargets` rows (those source suites relied on
/// the builder default rather than passing players per case).
const List<Player> kExpandPeaceMatrixDefaultGpRoster = <Player>[
  Player(id: kExpandPeaceMatrixGp1, displayName: 'GP1', isHuman: false),
  Player(id: kExpandPeaceMatrixGp2, displayName: 'GP2', isHuman: false),
  Player(id: kExpandPeaceMatrixGp3, displayName: 'GP3', isHuman: false),
  Player(id: kExpandPeaceMatrixGp4, displayName: 'GP4', isHuman: false),
];

typedef ExpandPeaceTargetDeciderFn =
    List<String> Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
class ExpandPeaceTargetDeciderMatrixCase {
  const ExpandPeaceTargetDeciderMatrixCase({
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

void runExpandPeaceTargetDeciderMatrixCases(
  String label,
  ExpandPeaceTargetDeciderFn fn,
  List<ExpandPeaceTargetDeciderMatrixCase> cases,
) {
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
