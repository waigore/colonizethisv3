// Case bodies for `planning_peace_collectors_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planning_peace_collectors.dart` (Refs #3941 topic split).
// Pins GP / minor / tribe / non-GP at-war peace collectors and GP-war presence.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_peace_collectors_test_support.dart';

void registerPlanningPeaceCollectorsGpCases() {
  group('gpFactionIdsAtWarWith', () {
    test('filters to Great Powers only and sorts ascending', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp3,
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsMinor1,
        planningPeaceCollectorsGp2,
      ]);
      expect(gpFactionIdsAtWarWith(game, snapshot), [
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
        planningPeaceCollectorsGp3,
      ]);
    });

    test('returns empty when no GP wars are active', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsMinor1,
      ]);
      expect(gpFactionIdsAtWarWith(game, snapshot), isEmpty);
    });

    test('sorts regardless of atWarWith iteration order', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp3,
        planningPeaceCollectorsGp2,
        planningPeaceCollectorsGp1,
      ]);
      final a = gpFactionIdsAtWarWith(game, snapshot);
      final b = gpFactionIdsAtWarWith(game, snapshot);
      expect(a, [
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
        planningPeaceCollectorsGp3,
      ]);
      expect(b, a);
    });
  });

  group('isAtWarWithAnyGreatPower (Refs #3717)', () {
    test('true when at least one at-war faction is a Great Power', () {
      final game = planningPeaceCollectorsGameWithGps();
      expect(
        isAtWarWithAnyGreatPower(
          game,
          planningPeaceCollectorsSnapshotWithAtWar([
            planningPeaceCollectorsTribe1,
            planningPeaceCollectorsGp2,
          ]),
        ),
        isTrue,
      );
    });

    test('false when no at-war faction resolves to a Great Power', () {
      final game = planningPeaceCollectorsGameWithGps();
      expect(
        isAtWarWithAnyGreatPower(
          game,
          planningPeaceCollectorsSnapshotWithAtWar([
            planningPeaceCollectorsTribe1,
            planningPeaceCollectorsMinor1,
          ]),
        ),
        isFalse,
      );
    });

    test('false on an empty atWarWith set', () {
      final game = planningPeaceCollectorsGameWithGps();
      expect(
        isAtWarWithAnyGreatPower(
          game,
          planningPeaceCollectorsSnapshotWithAtWar(const []),
        ),
        isFalse,
      );
    });

    test('agrees with gpFactionIdsAtWarWith.isNotEmpty (equivalence)', () {
      final game = planningPeaceCollectorsGameWithGps();
      for (final atWar in <List<String>>[
        const [],
        [planningPeaceCollectorsTribe1],
        [planningPeaceCollectorsMinor1, planningPeaceCollectorsTribe1],
        [planningPeaceCollectorsGp1],
        [
          planningPeaceCollectorsGp3,
          planningPeaceCollectorsTribe1,
          planningPeaceCollectorsGp1,
          planningPeaceCollectorsMinor1,
          planningPeaceCollectorsGp2,
        ],
      ]) {
        final snapshot = planningPeaceCollectorsSnapshotWithAtWar(atWar);
        expect(
          isAtWarWithAnyGreatPower(game, snapshot),
          gpFactionIdsAtWarWith(game, snapshot).isNotEmpty,
          reason: 'mismatch for atWarWith=$atWar',
        );
      }
    });
  });

  group('gpAtWarPeaceTargetsWhere (Refs #3717)', () {
    test('keeps only GP at-war factions matching the predicate, sorted', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp3,
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsMinor1,
        planningPeaceCollectorsGp2,
      ]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != planningPeaceCollectorsGp2,
        ),
        [planningPeaceCollectorsGp1, planningPeaceCollectorsGp3],
      );
    });

    test('keep-all equals gpFactionIdsAtWarWith (GP filter + sort)', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp3,
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsMinor1,
        planningPeaceCollectorsGp2,
      ]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        gpFactionIdsAtWarWith(game, snapshot),
      );
    });

    test('keep-none returns empty', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
        planningPeaceCollectorsGp3,
      ]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => false,
        ),
        isEmpty,
      );
    });

    test('never offers a non-GP even when the predicate would keep it', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsMinor1,
      ]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        isEmpty,
      );
    });

    test('result is sorted ascending regardless of atWarWith order', () {
      final game = planningPeaceCollectorsGameWithGps();
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: planningPeaceCollectorsSnapshotWithAtWar([
            planningPeaceCollectorsGp3,
            planningPeaceCollectorsGp1,
            planningPeaceCollectorsGp2,
          ]),
          keep: (_) => true,
        ),
        [
          planningPeaceCollectorsGp1,
          planningPeaceCollectorsGp2,
          planningPeaceCollectorsGp3,
        ],
      );
    });

    test('invokes keep exactly once per at-war GP in ascending order', () {
      final game = planningPeaceCollectorsGameWithGps();
      final snapshot = planningPeaceCollectorsSnapshotWithAtWar([
        planningPeaceCollectorsGp3,
        planningPeaceCollectorsTribe1,
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
      ]);
      final seen = <String>[];
      gpAtWarPeaceTargetsWhere(
        game: game,
        snapshot: snapshot,
        keep: (factionId) {
          seen.add(factionId);
          return true;
        },
      );
      expect(seen, [
        planningPeaceCollectorsGp1,
        planningPeaceCollectorsGp2,
        planningPeaceCollectorsGp3,
      ]);
    });
  });
}
