// Case bodies for `planning_peace_collectors_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planning_peace_collectors.dart` (Refs #3941 topic split).
// Pins GP / minor / tribe / non-GP at-war peace collectors and GP-war presence.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_peace_collectors_test_support.dart';

void registerPlanningPeaceCollectorsNonGpCasesTail() {
  group('minorAtWarPeaceTargetsWhere (Refs #3717)', () {
    test('keep == null keeps every at-war non-GP faction, sorted ascending', () {
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsGp2,
        'minorB',
        planningPeaceCollectorsGp1,
        'minorA',
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        ['minorA', 'minorB', planningPeaceCollectorsTribe1],
      );
    });

    test('keeps an at-war id that is no longer a registered minor or tribe', () {
      // Pins the `playerById == null` semantics (non-GP), distinct from the
      // minor/tribe membership collectors: an absorbed faction id still in
      // `atWarWith` is non-GP and must be retained.
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'absorbedX',
        planningPeaceCollectorsGp1,
        'minorA',
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        ['absorbedX', 'minorA'],
      );
    });

    test('never offers a Great Power even with a keep-all predicate', () {
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
        'minorA',
        planningPeaceCollectorsTribe1,
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['minorA', planningPeaceCollectorsTribe1],
      );
    });

    test('keeps only non-GP factions matching the predicate, sorted', () {
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'minorB',
        planningPeaceCollectorsTribe1,
        'minorA',
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'minorB',
        ),
        ['minorA', planningPeaceCollectorsTribe1],
      );
    });

    test('keep-none returns empty', () {
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        'minorA',
        planningPeaceCollectorsTribe1,
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('returns empty when only Great Powers are at war', () {
      final game = planningPeaceCollectorsGameWithMixedFactions();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        isEmpty,
      );
    });
  });

  group('peaceTargetsExcludingBlocker (Refs #3717)', () {
    test('excludes the blocker and sorts ascending', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [
            planningPeaceCollectorsGp3,
            planningPeaceCollectorsGp1,
            planningPeaceCollectorsGp2,
          ],
          blocker: planningPeaceCollectorsGp2,
        ),
        [planningPeaceCollectorsGp1, planningPeaceCollectorsGp3],
      );
    });

    test('null blocker keeps every faction, sorted ascending', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [
            planningPeaceCollectorsGp3,
            planningPeaceCollectorsGp1,
            planningPeaceCollectorsGp2,
          ],
          blocker: null,
        ),
        [
          planningPeaceCollectorsGp1,
          planningPeaceCollectorsGp2,
          planningPeaceCollectorsGp3,
        ],
      );
    });

    test('blocker absent from the list keeps every faction, sorted', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [planningPeaceCollectorsGp3, planningPeaceCollectorsGp1],
          blocker: planningPeaceCollectorsGp2,
        ),
        [planningPeaceCollectorsGp1, planningPeaceCollectorsGp3],
      );
    });

    test('empty input returns empty', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: const [],
          blocker: planningPeaceCollectorsGp1,
        ),
        isEmpty,
      );
    });

    test('result order is independent of input order', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [
            planningPeaceCollectorsGp1,
            planningPeaceCollectorsGp3,
            planningPeaceCollectorsGp2,
          ],
          blocker: planningPeaceCollectorsGp2,
        ),
        peaceTargetsExcludingBlocker(
          factionIds: [
            planningPeaceCollectorsGp3,
            planningPeaceCollectorsGp2,
            planningPeaceCollectorsGp1,
          ],
          blocker: planningPeaceCollectorsGp2,
        ),
      );
    });

    test('accepts a Set (threats.atWarWith) input and excludes blocker', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: <String>{
            planningPeaceCollectorsGp2,
            planningPeaceCollectorsMinor1,
            planningPeaceCollectorsGp1,
          },
          blocker: planningPeaceCollectorsGp2,
        ),
        [planningPeaceCollectorsGp1, planningPeaceCollectorsMinor1],
      );
    });
  });
}
