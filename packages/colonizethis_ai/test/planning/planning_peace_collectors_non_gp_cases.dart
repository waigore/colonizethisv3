// Case bodies for `planning_peace_collectors_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planning_peace_collectors.dart` (Refs #3941 topic split).
// Pins GP / minor / tribe / non-GP at-war peace collectors and GP-war presence.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_peace_collectors_test_support.dart';
import 'planning_peace_collectors_non_gp_cases_tail_cases.dart';

void registerPlanningPeaceCollectorsNonGpCases() {
  group('minorAtWarPeaceTargetsWhere (Refs #3717)', () {
    test('keep == null keeps every at-war minor, sorted ascending', () {
      final game = planningPeaceCollectorsGameWithMinors();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'minorC',
        planningPeaceCollectorsGp1,
        'minorA',
        planningPeaceCollectorsTribe1,
        'minorB',
      ]);
      expect(minorAtWarPeaceTargetsWhere(game: game, snapshot: snapshot), [
        'minorA',
        'minorB',
        'minorC',
      ]);
    });

    test('keeps only minors matching the predicate, sorted', () {
      final game = planningPeaceCollectorsGameWithMinors();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'minorC',
        'minorA',
        'minorB',
      ]);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'minorB',
        ),
        ['minorA', 'minorC'],
      );
    });

    test('never offers a GP or tribe even with a keep-all predicate', () {
      final game = planningPeaceCollectorsGameWithMinors();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsTribe1,
        'minorA',
      ]);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['minorA'],
      );
    });

    test('keep-none returns empty', () {
      final game = planningPeaceCollectorsGameWithMinors();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'minorA',
        'minorB',
      ]);
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('returns empty when no at-war minor is present', () {
      final game = planningPeaceCollectorsGameWithMinors();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsTribe1,
      ]);
      expect(
        minorAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = planningPeaceCollectorsGameWithMinors();
      expect(
        minorAtWarPeaceTargetsWhere(
          game: game,
          snapshot: planningPeaceCollectorsSnapshotWithAtWar([
            'minorC',
            'minorA',
            'minorB',
          ]),
        ),
        ['minorA', 'minorB', 'minorC'],
      );
    });
  });

  group('tribeAtWarPeaceTargetsWhere (Refs #3717)', () {
    test('keep == null keeps every at-war tribe, sorted ascending', () {
      final game = planningPeaceCollectorsGameWithTribes();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'tribeC',
        planningPeaceCollectorsGp1,
        'tribeA',
        'minorA',
        'tribeB',
      ]);
      expect(tribeAtWarPeaceTargetsWhere(game: game, snapshot: snapshot), [
        'tribeA',
        'tribeB',
        'tribeC',
      ]);
    });

    test('keeps only tribes matching the predicate, sorted', () {
      final game = planningPeaceCollectorsGameWithTribes();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'tribeC',
        'tribeA',
        'tribeB',
      ]);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'tribeB',
        ),
        ['tribeA', 'tribeC'],
      );
    });

    test('never offers a GP or minor even with a keep-all predicate', () {
      final game = planningPeaceCollectorsGameWithTribes();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        'minorA',
        'tribeA',
      ]);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['tribeA'],
      );
    });

    test('keep-none returns empty', () {
      final game = planningPeaceCollectorsGameWithTribes();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'tribeA',
        'tribeB',
      ]);
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('returns empty when no at-war tribe is present', () {
      final game = planningPeaceCollectorsGameWithTribes();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        'minorA',
      ]);
      expect(
        tribeAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = planningPeaceCollectorsGameWithTribes();
      expect(
        tribeAtWarPeaceTargetsWhere(
          game: game,
          snapshot: planningPeaceCollectorsSnapshotWithAtWar([
            'tribeC',
            'tribeA',
            'tribeB',
          ]),
        ),
        ['tribeA', 'tribeB', 'tribeC'],
      );
    });
  });

  registerPlanningPeaceCollectorsNonGpCasesTail();
}
