// Shared scaffolding for the table-driven consolidation of the diplomacy
// below-quota peace helper / integration suites (Refs #3941).
//
// Case tables live in sibling `*_cases.dart` modules so the single contract
// file `diplomacy_planner_below_quota_peace_test.dart` stays under the
// non-comment line gate. Former `*_part2_test.dart` / `*_part3_test.dart`
// shards are merged into that contract (1:1 row preservation).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

typedef BelowQuotaPeaceFn = List<String> Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

typedef BelowQuotaSinglePeaceFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One peace-helper row transcribed from a legacy shard `test(...)`.
class BelowQuotaPeaceCase {
  const BelowQuotaPeaceCase({
    required this.label,
    required this.build,
    required this.matcher,
    this.reason,
  });

  final String label;
  final (Game, AIWorldSnapshot) Function() build;
  final Object matcher;
  final String? reason;
}

void runBelowQuotaPeace(
  String groupLabel,
  BelowQuotaPeaceFn fn,
  List<BelowQuotaPeaceCase> cases,
) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final (game, snapshot) = c.build();
        expect(
          fn(game: game, snapshot: snapshot),
          c.matcher,
          reason: c.reason,
        );
      });
    }
  });
}

void runBelowQuotaSinglePeace(
  String groupLabel,
  BelowQuotaSinglePeaceFn fn,
  List<BelowQuotaPeaceCase> cases,
) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final (game, snapshot) = c.build();
        expect(
          fn(game: game, snapshot: snapshot),
          c.matcher,
          reason: c.reason,
        );
      });
    }
  });
}
