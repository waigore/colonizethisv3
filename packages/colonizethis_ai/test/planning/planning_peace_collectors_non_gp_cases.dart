// Case bodies for `planning_peace_collectors_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planning_peace_collectors.dart` (Refs #3941 topic split).
// Pins GP / minor / tribe / non-GP at-war peace collectors and GP-war presence.

import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_peace_collectors_test_support.dart';

void registerPlanningPeaceCollectorsNonGpCases() {
  group('minorAtWarPeaceTargetsWhere (Refs #3717)', () {
    Game gameWithMinors() => Game(
      id: 'g-3717-minor-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [
        Player(
          id: planningPeaceCollectorsGp1,
          displayName: 'GP1',
          isHuman: false,
        ),
      ],
      minorNations: const [
        MinorNation(id: 'minorA', displayName: 'MinorA'),
        MinorNation(id: 'minorB', displayName: 'MinorB'),
        MinorNation(id: 'minorC', displayName: 'MinorC'),
      ],
      tribes: const [
        Tribe(id: planningPeaceCollectorsTribe1, displayName: 'Tribe1'),
      ],
    );

    test('keep == null keeps every at-war minor, sorted ascending', () {
      final game = gameWithMinors();
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
      final game = gameWithMinors();
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
      final game = gameWithMinors();
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
      final game = gameWithMinors();
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
      final game = gameWithMinors();
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
      final game = gameWithMinors();
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
    Game gameWithTribes() => Game(
      id: 'g-3717-tribe-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [
        Player(
          id: planningPeaceCollectorsGp1,
          displayName: 'GP1',
          isHuman: false,
        ),
      ],
      minorNations: const [MinorNation(id: 'minorA', displayName: 'MinorA')],
      tribes: const [
        Tribe(id: 'tribeA', displayName: 'TribeA'),
        Tribe(id: 'tribeB', displayName: 'TribeB'),
        Tribe(id: 'tribeC', displayName: 'TribeC'),
      ],
    );

    test('keep == null keeps every at-war tribe, sorted ascending', () {
      final game = gameWithTribes();
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
      final game = gameWithTribes();
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
      final game = gameWithTribes();
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
      final game = gameWithTribes();
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
      final game = gameWithTribes();
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
      final game = gameWithTribes();
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

  group('nonGreatPowerAtWarPeaceTargetsWhere (Refs #3749)', () {
    Game gameWithMixedFactions() => Game(
      id: 'g-3749-non-gp-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [
        Player(
          id: planningPeaceCollectorsGp1,
          displayName: 'GP1',
          isHuman: false,
        ),
        Player(
          id: planningPeaceCollectorsGp2,
          displayName: 'GP2',
          isHuman: false,
        ),
      ],
      minorNations: const [
        MinorNation(id: 'minorA', displayName: 'MinorA'),
        MinorNation(id: 'minorB', displayName: 'MinorB'),
      ],
      tribes: const [
        Tribe(id: planningPeaceCollectorsTribe1, displayName: 'Tribe1'),
      ],
    );

    test('keep == null keeps every at-war non-GP faction, sorted ascending', () {
      final game = gameWithMixedFactions();
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
      final game = gameWithMixedFactions();
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
      final game = gameWithMixedFactions();
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
      final game = gameWithMixedFactions();
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
      final game = gameWithMixedFactions();
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
      final game = gameWithMixedFactions();
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
