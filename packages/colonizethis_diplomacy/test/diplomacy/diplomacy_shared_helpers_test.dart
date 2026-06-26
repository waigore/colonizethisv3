import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage for the shared diplomacy resolution helpers consolidated from the
/// per-resolver copy-paste duplicates (Refs #3419): [isTargetHumanGp],
/// [atWarGreatPowerCount], [findHumanDecision], and [debitPlayerTreasury];
/// plus the [resolveHumanGatedDecision] control-flow template that routes the
/// four resolvers' pending-human-decision branch tail (Refs #3715).
void main() {
  group('isTargetHumanGp', () {
    test('positive: human-controlled player is reported human', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      expect(isTargetHumanGp(game, 'h1'), isTrue);
    });

    test('negative: AI-controlled player is not human', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp2', displayName: 'AI', isHuman: false)],
      );
      expect(isTargetHumanGp(game, 'gp2'), isFalse);
    });

    test('negative: unknown faction id is not human', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'gp2', displayName: 'AI', isHuman: false)],
      );
      expect(isTargetHumanGp(game, 'minor1'), isFalse);
    });
  });

  group('atWarGreatPowerCount', () {
    test('positive: counts only Great Powers at war with the subject', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
          Player(id: 'gp3', displayName: 'C', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
          // At peace: must not count.
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp3'),
          // At war but the other party is not a Great Power: must not count.
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atWar,
          ),
        ],
      );
      final membership = DiplomacyFactionMembership.from(game);
      expect(atWarGreatPowerCount(game, 'gp1', membership), 1);
    });

    test('negative: subject with no war relations counts zero', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
        ],
      );
      final membership = DiplomacyFactionMembership.from(game);
      expect(atWarGreatPowerCount(game, 'gp1', membership), 0);
    });
  });

  group('findHumanDecision', () {
    test('positive: returns the first matching decision', () {
      const decisions = ['a', 'bb', 'cc'];
      expect(
        findHumanDecision<String>(decisions, (d) => d.length == 2),
        'bb',
      );
    });

    test('negative: null list returns null', () {
      expect(findHumanDecision<String>(null, (_) => true), isNull);
    });

    test('negative: no match returns null', () {
      const decisions = ['a', 'b'];
      expect(
        findHumanDecision<String>(decisions, (d) => d == 'z'),
        isNull,
      );
    });
  });

  group('resolveHumanGatedDecision (Refs #3715)', () {
    test('AI-controlled decider routes to onAiResolve only', () {
      var matchesCalls = 0;
      final outcome = resolveHumanGatedDecision<String, String>(
        isHumanControlled: false,
        decisions: const ['x'],
        matches: (_) {
          matchesCalls++;
          return true;
        },
        onAiResolve: () => 'ai',
        onPending: () => 'pending',
        onHumanDecision: (_) => 'human',
      );
      expect(outcome, 'ai');
      // Decisions are never consulted for an AI decider (evaluation order).
      expect(matchesCalls, 0);
    });

    test('human decider with a matching decision routes to onHumanDecision', () {
      final outcome = resolveHumanGatedDecision<String, String>(
        isHumanControlled: true,
        decisions: const ['a', 'bb', 'cc'],
        matches: (d) => d.length == 2,
        onAiResolve: () => 'ai',
        onPending: () => 'pending',
        // First match wins, mirroring findHumanDecision.
        onHumanDecision: (decision) => 'human:$decision',
      );
      expect(outcome, 'human:bb');
    });

    test('human decider with no matching decision routes to onPending', () {
      final outcome = resolveHumanGatedDecision<String, String>(
        isHumanControlled: true,
        decisions: const ['a', 'b'],
        matches: (d) => d == 'z',
        onAiResolve: () => 'ai',
        onPending: () => 'pending',
        onHumanDecision: (_) => 'human',
      );
      expect(outcome, 'pending');
    });

    test('human decider with null decisions routes to onPending', () {
      final outcome = resolveHumanGatedDecision<String, String>(
        isHumanControlled: true,
        decisions: null,
        matches: (_) => true,
        onAiResolve: () => 'ai',
        onPending: () => 'pending',
        onHumanDecision: (_) => 'human',
      );
      expect(outcome, 'pending');
    });

    test('exactly one callback runs per invocation', () {
      var ai = 0;
      var pending = 0;
      var human = 0;
      resolveHumanGatedDecision<String, void>(
        isHumanControlled: true,
        decisions: const ['match'],
        matches: (d) => d == 'match',
        onAiResolve: () => ai++,
        onPending: () => pending++,
        onHumanDecision: (_) => human++,
      );
      expect([ai, pending, human], [0, 0, 1]);
    });
  });

  group('debitPlayerTreasury', () {
    List<Player> players() => const [
          Player(id: 'gp1', displayName: 'A', isHuman: false, treasury: 1000),
          Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 500),
        ];

    test('positive: debits the target and returns a fresh copy', () {
      final original = players();
      final result = debitPlayerTreasury(original, 1, 200);
      expect(result[1].treasury, 300);
      expect(result[0].treasury, 1000);
      // Original list/players are untouched.
      expect(identical(result, original), isFalse);
      expect(original[1].treasury, 500);
    });

    test('negative: out-of-range index returns the same list instance', () {
      final original = players();
      expect(identical(debitPlayerTreasury(original, -1, 200), original), isTrue);
      expect(
        identical(debitPlayerTreasury(original, 5, 200), original),
        isTrue,
      );
    });

    test('negative: non-positive amount returns the same list instance', () {
      final original = players();
      expect(identical(debitPlayerTreasury(original, 0, 0), original), isTrue);
      expect(
        identical(debitPlayerTreasury(original, 0, -50), original),
        isTrue,
      );
    });
  });
}
