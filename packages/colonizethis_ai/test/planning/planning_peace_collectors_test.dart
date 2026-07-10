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

void main() {
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

  group('minorAtWarPeaceTargetsWhere (Refs #3717)', () {
    Game gameWithMinors() => Game(
      id: 'g-3717-minor-peace',
      worldState: WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(provinces: []),
        newWorld: const RegionData(provinces: []),
      ),
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [
        MinorNation(id: 'minorA', displayName: 'MinorA'),
        MinorNation(id: 'minorB', displayName: 'MinorB'),
        MinorNation(id: 'minorC', displayName: 'MinorC'),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    );

    test('keep == null keeps every at-war minor, sorted ascending', () {
      final game = gameWithMinors();
      final snapshot = _snapshotWithAtWar([
        'minorC',
        _gp1,
        'minorA',
        _tribe1,
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
      final snapshot = _snapshotWithAtWar(['minorC', 'minorA', 'minorB']);
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
      final snapshot = _snapshotWithAtWar([_gp1, _tribe1, 'minorA']);
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
      final snapshot = _snapshotWithAtWar(['minorA', 'minorB']);
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
      final snapshot = _snapshotWithAtWar([_gp1, _tribe1]);
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
          snapshot: _snapshotWithAtWar(['minorC', 'minorA', 'minorB']),
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
      players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
      minorNations: const [MinorNation(id: 'minorA', displayName: 'MinorA')],
      tribes: const [
        Tribe(id: 'tribeA', displayName: 'TribeA'),
        Tribe(id: 'tribeB', displayName: 'TribeB'),
        Tribe(id: 'tribeC', displayName: 'TribeC'),
      ],
    );

    test('keep == null keeps every at-war tribe, sorted ascending', () {
      final game = gameWithTribes();
      final snapshot = _snapshotWithAtWar([
        'tribeC',
        _gp1,
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
      final snapshot = _snapshotWithAtWar(['tribeC', 'tribeA', 'tribeB']);
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
      final snapshot = _snapshotWithAtWar([_gp1, 'minorA', 'tribeA']);
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
      final snapshot = _snapshotWithAtWar(['tribeA', 'tribeB']);
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
      final snapshot = _snapshotWithAtWar([_gp1, 'minorA']);
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
          snapshot: _snapshotWithAtWar(['tribeC', 'tribeA', 'tribeB']),
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
        Player(id: _gp1, displayName: 'GP1', isHuman: false),
        Player(id: _gp2, displayName: 'GP2', isHuman: false),
      ],
      minorNations: const [
        MinorNation(id: 'minorA', displayName: 'MinorA'),
        MinorNation(id: 'minorB', displayName: 'MinorB'),
      ],
      tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
    );

    test('keep == null keeps every at-war non-GP faction, sorted ascending', () {
      final game = gameWithMixedFactions();
      final snapshot = _snapshotWithAtWar([
        _tribe1,
        _gp2,
        'minorB',
        _gp1,
        'minorA',
      ]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        ['minorA', 'minorB', _tribe1],
      );
    });

    test('keeps an at-war id that is no longer a registered minor or tribe', () {
      // Pins the `playerById == null` semantics (non-GP), distinct from the
      // minor/tribe membership collectors: an absorbed faction id still in
      // `atWarWith` is non-GP and must be retained.
      final game = gameWithMixedFactions();
      final snapshot = _snapshotWithAtWar(['absorbedX', _gp1, 'minorA']);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot),
        ['absorbedX', 'minorA'],
      );
    });

    test('never offers a Great Power even with a keep-all predicate', () {
      final game = gameWithMixedFactions();
      final snapshot = _snapshotWithAtWar([_gp1, _gp2, 'minorA', _tribe1]);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (_) => true,
        ),
        ['minorA', _tribe1],
      );
    });

    test('keeps only non-GP factions matching the predicate, sorted', () {
      final game = gameWithMixedFactions();
      final snapshot = _snapshotWithAtWar(['minorB', _tribe1, 'minorA']);
      expect(
        nonGreatPowerAtWarPeaceTargetsWhere(
          game: game,
          snapshot: snapshot,
          keep: (factionId) => factionId != 'minorB',
        ),
        ['minorA', _tribe1],
      );
    });

    test('keep-none returns empty', () {
      final game = gameWithMixedFactions();
      final snapshot = _snapshotWithAtWar(['minorA', _tribe1]);
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
      final snapshot = _snapshotWithAtWar([_gp1, _gp2]);
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
          factionIds: [_gp3, _gp1, _gp2],
          blocker: _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('null blocker keeps every faction, sorted ascending', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp1, _gp2],
          blocker: null,
        ),
        [_gp1, _gp2, _gp3],
      );
    });

    test('blocker absent from the list keeps every faction, sorted', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp1],
          blocker: _gp2,
        ),
        [_gp1, _gp3],
      );
    });

    test('empty input returns empty', () {
      expect(
        peaceTargetsExcludingBlocker(factionIds: const [], blocker: _gp1),
        isEmpty,
      );
    });

    test('result order is independent of input order', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: [_gp1, _gp3, _gp2],
          blocker: _gp2,
        ),
        peaceTargetsExcludingBlocker(
          factionIds: [_gp3, _gp2, _gp1],
          blocker: _gp2,
        ),
      );
    });

    test('accepts a Set (threats.atWarWith) input and excludes blocker', () {
      expect(
        peaceTargetsExcludingBlocker(
          factionIds: <String>{_gp2, _minor1, _gp1},
          blocker: _gp2,
        ),
        [_gp1, _minor1],
      );
    });
  });

}
