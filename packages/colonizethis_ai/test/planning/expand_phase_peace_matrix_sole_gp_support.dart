// Shared helpers for sole-GP peace matrix case modules (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String expandPeaceMatrixGp1 = 'gp1';
const String expandPeaceMatrixGp2 = 'gp2';
const String expandPeaceMatrixGp3 = 'gp3';
const String expandPeaceMatrixMinor1 = 'minor1';
const String expandPeaceMatrixTribe1 = 'tribe1';

typedef ExpandPeaceSoleGpPeaceTargetFn =
    String? Function({required Game game, required AIWorldSnapshot snapshot});

AIWorldSnapshot expandPeaceMatrixSnapshot({
  required String playerId,
  required List<String> atWarWith,
  int oldWorldProvincesOwned = 0,
  List<String> invadableProvinceIdsSorted = const [],
}) => AIWorldSnapshot(
  playerId: playerId,
  threats: ThreatSummary(atWarWith: atWarWith),
  opportunities: const OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    invadableProvinceIdsSorted: invadableProvinceIdsSorted,
  ),
  colonial: const ColonialSummary(),
  economy: const EconomySummary(),
  relations: const {},
);

class ExpandPeaceSoleGpCase {
  ExpandPeaceSoleGpCase({
    required this.name,
    required this.game,
    required this.snapshot,
    this.expected,
    this.reason,
  });

  final String name;
  final Game game;
  final AIWorldSnapshot snapshot;
  final String? expected;
  final String? reason;
}

void runExpandPeaceSoleGpDecider(
  String label,
  ExpandPeaceSoleGpPeaceTargetFn fn,
  List<ExpandPeaceSoleGpCase> cases,
) {
  group(label, () {
    for (final c in cases) {
      test(c.name, () {
        final result = fn(game: c.game, snapshot: c.snapshot);
        if (c.expected == null) {
          expect(result, isNull, reason: c.reason);
        } else {
          expect(result, c.expected, reason: c.reason);
        }
      });
    }
  });
}
