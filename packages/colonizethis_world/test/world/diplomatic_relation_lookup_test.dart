import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  Game gameWithRelations(List<DiplomacyRelation> relations) =>
      TestFixtures.minimalGame(
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: false),
          Player(id: 'c', displayName: 'C', isHuman: false),
        ],
        diplomacyRelations: relations,
      );

  group('pairKey', () {
    test('orders the pair deterministically regardless of argument order', () {
      expect(pairKey('a', 'b'), 'a|b');
      expect(pairKey('b', 'a'), 'a|b');
    });
  });

  group('getRelation', () {
    test('returns the relation for an existing pair (either order)', () {
      final game = gameWithRelations(const [
        DiplomacyRelation(factionId1: 'a', factionId2: 'b'),
      ]);
      expect(getRelation(game, 'a', 'b'), isNotNull);
      expect(getRelation(game, 'b', 'a'), isNotNull);
    });

    test('returns null for an unknown pair', () {
      final game = gameWithRelations(const []);
      expect(getRelation(game, 'a', 'b'), isNull);
    });
  });

  group('factionsAtWar', () {
    test('true when the relation is in the at-war state', () {
      final game = gameWithRelations(const [
        DiplomacyRelation(
          factionId1: 'a',
          factionId2: 'b',
          state: RelationState.atWar,
        ),
      ]);
      expect(factionsAtWar(game, 'a', 'b'), isTrue);
    });

    test('false at peace and false for unknown pairs', () {
      final game = gameWithRelations(const [
        DiplomacyRelation(factionId1: 'a', factionId2: 'b'),
      ]);
      expect(factionsAtWar(game, 'a', 'b'), isFalse);
      expect(factionsAtWar(game, 'a', 'c'), isFalse);
    });
  });

  group('hostileFactionsByFaction / enemiesOf', () {
    test('builds undirected adjacency from at-war relations only', () {
      final game = gameWithRelations(const [
        DiplomacyRelation(
          factionId1: 'a',
          factionId2: 'b',
          state: RelationState.atWar,
        ),
        DiplomacyRelation(factionId1: 'a', factionId2: 'c'),
      ]);
      final hostile = hostileFactionsByFaction(game);
      expect(hostile['a'], contains('b'));
      expect(hostile['b'], contains('a'));
      expect(hostile.containsKey('c'), isFalse);
    });

    test('enemiesOf returns the at-war set, empty when none', () {
      final game = gameWithRelations(const [
        DiplomacyRelation(
          factionId1: 'a',
          factionId2: 'b',
          state: RelationState.atWar,
        ),
      ]);
      expect(enemiesOf(game, 'a'), {'b'});
      expect(enemiesOf(game, 'c'), isEmpty);
    });
  });
}
