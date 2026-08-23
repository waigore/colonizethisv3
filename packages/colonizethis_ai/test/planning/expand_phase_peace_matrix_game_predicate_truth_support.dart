// Topic-split case module (Refs #3997 Phase 8).
// Pin/row coverage preserved 1:1 from the former combined cases file.

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

const String expandPeaceMatrixGp1 = 'gp1';
const String expandPeaceMatrixGp2 = 'gp2';
const String expandPeaceMatrixGp5 = 'gp5';
const String expandPeaceMatrixGp6 = 'gp6';
const String expandPeaceMatrixMinor1 = 'minor1';
const String expandPeaceMatrixMinor2 = 'minor2';
const String expandPeaceMatrixTribe1 = 'tribe1';

const List<Player> expandPeaceMatrixGp5Gp6 = <Player>[
  Player(id: expandPeaceMatrixGp5, displayName: 'P5', isHuman: false),
  Player(id: expandPeaceMatrixGp6, displayName: 'P6', isHuman: false),
];
const List<Player> expandPeaceMatrixGp1Gp2 = <Player>[
  Player(id: expandPeaceMatrixGp1, displayName: 'GP1', isHuman: false),
  Player(id: expandPeaceMatrixGp2, displayName: 'GP2', isHuman: false),
];
const List<Player> expandPeaceMatrixGp1Only = <Player>[
  Player(id: expandPeaceMatrixGp1, displayName: 'GP1', isHuman: false),
];

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
class ExpandPeaceMatrixPredicateCase {
  const ExpandPeaceMatrixPredicateCase({
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

typedef ExpandPeaceMatrixPredicateFn =
    bool Function({required Game game, required AIWorldSnapshot snapshot});

void runExpandPeaceMatrixPredicateCases(
  String label,
  ExpandPeaceMatrixPredicateFn fn,
  List<ExpandPeaceMatrixPredicateCase> cases,
) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        expect(
          fn(
            game: buildExpandPeaceMatrixGame(
              owProvinces: c.owProvinces,
              players: c.players,
              minorNations: c.minorNations,
              tribes: c.tribes,
              nwProvinces: c.nwProvinces,
              turnNumber: c.turnNumber,
            ),
            snapshot: buildExpandPeaceMatrixSnapshot(
              playerId: c.playerId,
              atWarWith: c.atWarWith,
              oldWorldProvincesOwned: c.ow,
              invadableProvinceIdsSorted: c.invadable,
            ),
          ),
          c.expected ? isTrue : isFalse,
          reason: c.reason,
        );
      });
    }
  });
}

const Province expandPeaceMatrixGp6Frontier = Province(
  id: 'oldWorld|gp6_frontier',
  regionId: 'oldWorld',
  ownerId: expandPeaceMatrixGp6,
);
