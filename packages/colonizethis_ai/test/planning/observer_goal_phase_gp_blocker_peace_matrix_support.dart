// Shared scaffolding for the table-driven matrix consolidation of the
// observer-phase GP-blocker / peace-target branch-pin suites (Refs #3749).
//
// Fixture families live in
// `observer_goal_phase_gp_blocker_peace_matrix_support_fixtures.dart`;
// this library re-exports them and hosts the truth-table runners.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

export 'observer_goal_phase_gp_blocker_peace_matrix_support_fixtures.dart';

typedef BlockerFn = String? Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One blocker-contract branch row transcribed from a source
/// `*_branches_test`. [matcher] is the verbatim expected blocker (a faction
/// id or `isNull`) and [reason] the verbatim regression rationale.
class BlockerCase {
  const BlockerCase({
    required this.label,
    required this.build,
    required this.matcher,
    required this.reason,
  });

  final String label;
  final (Game, AIWorldSnapshot) Function() build;
  final Object matcher;
  final String reason;
}

void runBlocker(String groupLabel, BlockerFn fn, List<BlockerCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final (game, snapshot) = c.build();
        expect(fn(game: game, snapshot: snapshot), c.matcher, reason: c.reason);
      });
    }
  });
}

typedef PeaceFn = List<String> Function({
  required Game game,
  required AIWorldSnapshot snapshot,
});

/// One peace-target guard-branch row transcribed from a source
/// `*_branches_test`.
class PeaceCase {
  const PeaceCase({
    required this.label,
    required this.gameBuilder,
    required this.snapshot,
    required this.expectedPeace,
    this.peaceReason,
    this.expectedPhase,
    this.phaseReason,
    this.blockerFn,
    this.blockerExpected,
    this.blockerReason,
  });

  final String label;
  final Game Function() gameBuilder;
  final AIWorldSnapshot snapshot;
  final Object expectedPeace;
  final String? peaceReason;
  final ObserverGoalPhase? expectedPhase;
  final String? phaseReason;
  final BlockerFn? blockerFn;
  final Object? blockerExpected;
  final String? blockerReason;
}

void runPeace(String groupLabel, PeaceFn fn, List<PeaceCase> cases) {
  group(groupLabel, () {
    for (final c in cases) {
      test(c.label, () {
        final game = c.gameBuilder();
        final expectedPhase = c.expectedPhase;
        if (expectedPhase != null) {
          expect(
            observerGoalPhaseFor(snapshot: c.snapshot, game: game),
            expectedPhase,
            reason: c.phaseReason,
          );
        }
        final blockerFn = c.blockerFn;
        if (blockerFn != null) {
          expect(
            blockerFn(game: game, snapshot: c.snapshot),
            c.blockerExpected,
            reason: c.blockerReason,
          );
        }
        expect(
          fn(game: game, snapshot: c.snapshot),
          c.expectedPeace,
          reason: c.peaceReason,
        );
      });
    }
  });
}
