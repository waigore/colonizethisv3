// Case bodies for `planning_peace_collectors_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `planning_peace_collectors.dart` (Refs #3941 topic split).
// Pins GP / minor / tribe / non-GP at-war peace collectors and GP-war presence.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

Game _gameWithGps() {
  return Game(
    id: 'g-3278-planning-helpers',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(provinces: []),
      newWorld: const RegionData(provinces: []),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
      Player(id: _gp3, displayName: 'GP3', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}


void registerPlanningPeaceCollectorsGpCases() {
  group('gpFactionIdsAtWarWith', () {
    test('filters to Great Powers only and sorts ascending', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
      expect(gpFactionIdsAtWarWith(game, snapshot), [_gp1, _gp2, _gp3]);
    });

    test('returns empty when no GP wars are active', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_tribe1, _minor1]);
      expect(gpFactionIdsAtWarWith(game, snapshot), isEmpty);
    });

    test('sorts regardless of atWarWith iteration order', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _gp2, _gp1]);
      final a = gpFactionIdsAtWarWith(game, snapshot);
      final b = gpFactionIdsAtWarWith(game, snapshot);
      expect(a, [_gp1, _gp2, _gp3]);
      expect(b, a);
    });
  });

  group('isAtWarWithAnyGreatPower (Refs #3717)', () {
    test('true when at least one at-war faction is a Great Power', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar([_tribe1, _gp2])),
        isTrue,
      );
    });

    test('false when no at-war faction resolves to a Great Power', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar([_tribe1, _minor1])),
        isFalse,
      );
    });

    test('false on an empty atWarWith set', () {
      final game = _gameWithGps();
      expect(
        isAtWarWithAnyGreatPower(game, _snapshotWithAtWar(const [])),
        isFalse,
      );
    });

    test('agrees with gpFactionIdsAtWarWith.isNotEmpty (equivalence)', () {
      final game = _gameWithGps();
      for (final atWar in <List<String>>[
        const [],
        [_tribe1],
        [_minor1, _tribe1],
        [_gp1],
        [_gp3, _tribe1, _gp1, _minor1, _gp2],
      ]) {
        final snapshot = _snapshotWithAtWar(atWar);
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
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('keep-all equals gpFactionIdsAtWarWith (GP filter + sort)', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _minor1, _gp2]);
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
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp1, _gp2, _gp3]);
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
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_tribe1, _minor1]);
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
      final game = _gameWithGps();
      expect(
        gpAtWarPeaceTargetsWhere(
          game: game,
          snapshot: _snapshotWithAtWar([_gp3, _gp1, _gp2]),
          keep: (_) => true,
        ),
        [_gp1, _gp2, _gp3],
      );
    });

    test('invokes keep exactly once per at-war GP in ascending order', () {
      final game = _gameWithGps();
      final snapshot = _snapshotWithAtWar([_gp3, _tribe1, _gp1, _gp2]);
      final seen = <String>[];
      gpAtWarPeaceTargetsWhere(
        game: game,
        snapshot: snapshot,
        keep: (factionId) {
          seen.add(factionId);
          return true;
        },
      );
      expect(seen, [_gp1, _gp2, _gp3]);
    });
  });

}
