// Unit tests for the shared faction-query helpers in
// `packages/colonizethis_ai/lib/src/util/faction_query.dart` (Refs #2509).
//
// The helpers replaced three duplicated private predicates previously held
// by `conquest_planner.dart`, `diplomatic_candidate_scoring.dart`, and the
// inline `minorNations.any || tribes.any` pattern in
// `war_desire_calculator.dart`. The tests pin the canonical truth table so
// future drift between callers is caught at this single unit boundary
// rather than at runtime through whichever scoring path happens to fire.

import 'package:colonizethis_ai/src/util/faction_query.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _minorA = 'minorA';
const String _minorB = 'minorB';
const String _tribeA = 'tribeA';
const String _tribeB = 'tribeB';

/// Minimal `Game` scaffold with deterministic minor-nation and tribe
/// rosters; province / world state details are irrelevant for these
/// predicates.
Game _game({
  List<MinorNation> minorNations = const [
    MinorNation(id: _minorA, displayName: 'Minor A'),
    MinorNation(id: _minorB, displayName: 'Minor B'),
  ],
  List<Tribe> tribes = const [
    Tribe(id: _tribeA, displayName: 'Tribe A'),
    Tribe(id: _tribeB, displayName: 'Tribe B'),
  ],
}) {
  return Game(
    id: 'g-faction-query',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: _gp1, displayName: 'GP1', isHuman: false)],
    minorNations: minorNations,
    tribes: tribes,
  );
}

void main() {
  group('isMinorFaction', () {
    test('true for ids matching a MinorNation entry', () {
      final game = _game();
      expect(isMinorFaction(game, _minorA), isTrue);
      expect(isMinorFaction(game, _minorB), isTrue);
    });

    test('false for tribe ids', () {
      final game = _game();
      expect(isMinorFaction(game, _tribeA), isFalse);
      expect(isMinorFaction(game, _tribeB), isFalse);
    });

    test('false for player ids and unknown ids', () {
      final game = _game();
      expect(isMinorFaction(game, _gp1), isFalse);
      expect(isMinorFaction(game, 'no-such-faction'), isFalse);
      expect(isMinorFaction(game, ''), isFalse);
    });

    test('false on an empty minor-nation roster', () {
      final game = _game(minorNations: const []);
      expect(isMinorFaction(game, _minorA), isFalse);
    });
  });

  group('isTribeFaction', () {
    test('true for ids matching a Tribe entry', () {
      final game = _game();
      expect(isTribeFaction(game, _tribeA), isTrue);
      expect(isTribeFaction(game, _tribeB), isTrue);
    });

    test('false for minor-nation ids', () {
      final game = _game();
      expect(isTribeFaction(game, _minorA), isFalse);
      expect(isTribeFaction(game, _minorB), isFalse);
    });

    test('false for player ids and unknown ids', () {
      final game = _game();
      expect(isTribeFaction(game, _gp1), isFalse);
      expect(isTribeFaction(game, 'no-such-faction'), isFalse);
      expect(isTribeFaction(game, ''), isFalse);
    });

    test('false on an empty tribe roster', () {
      final game = _game(tribes: const []);
      expect(isTribeFaction(game, _tribeA), isFalse);
    });
  });

  group('isMinorOrTribeFaction', () {
    test('true for ids matching a MinorNation entry', () {
      final game = _game();
      expect(isMinorOrTribeFaction(game, _minorA), isTrue);
      expect(isMinorOrTribeFaction(game, _minorB), isTrue);
    });

    test('true for ids matching a Tribe entry', () {
      final game = _game();
      expect(isMinorOrTribeFaction(game, _tribeA), isTrue);
      expect(isMinorOrTribeFaction(game, _tribeB), isTrue);
    });

    test('false for player ids, empty ids, and unknown ids', () {
      final game = _game();
      expect(isMinorOrTribeFaction(game, _gp1), isFalse);
      expect(isMinorOrTribeFaction(game, ''), isFalse);
      expect(isMinorOrTribeFaction(game, 'no-such-faction'), isFalse);
    });

    test('false on a game with no minors and no tribes', () {
      final game = _game(minorNations: const [], tribes: const []);
      expect(isMinorOrTribeFaction(game, _minorA), isFalse);
      expect(isMinorOrTribeFaction(game, _tribeA), isFalse);
    });

    test('deterministic — repeated calls return the same result', () {
      final game = _game();
      final first = isMinorOrTribeFaction(game, _minorA);
      final second = isMinorOrTribeFaction(game, _minorA);
      expect(first, equals(second));
    });
  });
}
