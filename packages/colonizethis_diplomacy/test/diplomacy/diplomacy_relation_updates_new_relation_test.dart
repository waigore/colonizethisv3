import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Coverage for the "no existing relation" branches of the relation-update
/// helpers in `diplomacy_relation_updates.dart` (Refs #3290 test migration —
/// per-package coverage gate for `colonizethis_diplomacy`).
void main() {
  group('canonicalPairIds', () {
    test('orders ids canonically regardless of argument order', () {
      final a = canonicalPairIds('gp2', 'gp1');
      final b = canonicalPairIds('gp1', 'gp2');
      expect(a, b);
    });
  });

  group('applyGrantAidModifier with no existing relation', () {
    test('creates a new relation seeded from neutral + 5', () {
      final relations = applyGrantAidModifier(
        relations: const [],
        gpId: 'gp1',
        targetId: 'minor1',
        turn: 4,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 5);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 5));
      expect(rel.lastInteractionTurn, 4);
    });
  });

  group('applySubsidyBoost with no existing relation', () {
    test('creates a new relation seeded from neutral + boost', () {
      final relations = applySubsidyBoost(
        relations: const [],
        payerId: 'gp1',
        targetId: 'tribe1',
        boost: 6,
        turn: 8,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 6);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 6));
      expect(rel.lastInteractionTurn, 8);
    });
  });

  group('setWarStateForPair with no existing relation', () {
    test('creates a hostile at-war relation', () {
      final relations = setWarStateForPair(
        relations: const [],
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 2,
      );
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.state, RelationState.atWar);
      expect(rel.level, RelationLevel.hostile);
      expect(rel.sinceTurn, 2);
      // War invariant: a freshly created at-war relation is never allied.
      expect(rel.formalAlliance, isFalse);
    });
  });

  group('setWarStateForPair clears a formal alliance (war invariant)', () {
    test('transitioning an allied pair to war drops formalAlliance', () {
      const allied = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        level: RelationLevel.allied,
        formalAlliance: true,
      );
      final relations = setWarStateForPair(
        relations: const [allied],
        gpId: 'gp1',
        targetId: 'gp2',
        turn: 5,
      );
      final rel = relations.single;
      expect(rel.state, RelationState.atWar);
      // SPEC/game/diplomacy.md § Alliances: a formal alliance cannot coexist
      // with war, so the war transition clears the flag.
      expect(rel.formalAlliance, isFalse);
    });
  });
}
