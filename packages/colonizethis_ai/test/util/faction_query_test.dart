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

import '../support/faction_query_test_support.dart';

void main() {
  group('isMinorFaction', () {
    test('true for ids matching a MinorNation entry', () {
      final game = factionQueryGame();
      expect(isMinorFaction(game, kFactionQueryMinorA), isTrue);
      expect(isMinorFaction(game, kFactionQueryMinorB), isTrue);
    });

    test('false for tribe ids', () {
      final game = factionQueryGame();
      expect(isMinorFaction(game, kFactionQueryTribeA), isFalse);
      expect(isMinorFaction(game, kFactionQueryTribeB), isFalse);
    });

    test('false for player ids and unknown ids', () {
      final game = factionQueryGame();
      expect(isMinorFaction(game, kFactionQueryGp1), isFalse);
      expect(isMinorFaction(game, 'no-such-faction'), isFalse);
      expect(isMinorFaction(game, ''), isFalse);
    });

    test('false on an empty minor-nation roster', () {
      final game = factionQueryGame(minorNations: const []);
      expect(isMinorFaction(game, kFactionQueryMinorA), isFalse);
    });
  });

  group('isTribeFaction', () {
    test('true for ids matching a Tribe entry', () {
      final game = factionQueryGame();
      expect(isTribeFaction(game, kFactionQueryTribeA), isTrue);
      expect(isTribeFaction(game, kFactionQueryTribeB), isTrue);
    });

    test('false for minor-nation ids', () {
      final game = factionQueryGame();
      expect(isTribeFaction(game, kFactionQueryMinorA), isFalse);
      expect(isTribeFaction(game, kFactionQueryMinorB), isFalse);
    });

    test('false for player ids and unknown ids', () {
      final game = factionQueryGame();
      expect(isTribeFaction(game, kFactionQueryGp1), isFalse);
      expect(isTribeFaction(game, 'no-such-faction'), isFalse);
      expect(isTribeFaction(game, ''), isFalse);
    });

    test('false on an empty tribe roster', () {
      final game = factionQueryGame(tribes: const []);
      expect(isTribeFaction(game, kFactionQueryTribeA), isFalse);
    });
  });

  group('isMinorOrTribeFaction', () {
    test('true for ids matching a MinorNation entry', () {
      final game = factionQueryGame();
      expect(isMinorOrTribeFaction(game, kFactionQueryMinorA), isTrue);
      expect(isMinorOrTribeFaction(game, kFactionQueryMinorB), isTrue);
    });

    test('true for ids matching a Tribe entry', () {
      final game = factionQueryGame();
      expect(isMinorOrTribeFaction(game, kFactionQueryTribeA), isTrue);
      expect(isMinorOrTribeFaction(game, kFactionQueryTribeB), isTrue);
    });

    test('false for player ids, empty ids, and unknown ids', () {
      final game = factionQueryGame();
      expect(isMinorOrTribeFaction(game, kFactionQueryGp1), isFalse);
      expect(isMinorOrTribeFaction(game, ''), isFalse);
      expect(isMinorOrTribeFaction(game, 'no-such-faction'), isFalse);
    });

    test('false on a game with no minors and no tribes', () {
      final game = factionQueryGame(minorNations: const [], tribes: const []);
      expect(isMinorOrTribeFaction(game, kFactionQueryMinorA), isFalse);
      expect(isMinorOrTribeFaction(game, kFactionQueryTribeA), isFalse);
    });

    test('deterministic — repeated calls return the same result', () {
      final game = factionQueryGame();
      final first = isMinorOrTribeFaction(game, kFactionQueryMinorA);
      final second = isMinorOrTribeFaction(game, kFactionQueryMinorA);
      expect(first, equals(second));
    });
  });
}
