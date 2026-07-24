import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('grantAidRelationUpdater via RelationUpsertIndex', () {
    test('updates existing relation when pair already present', () {
      final index = RelationUpsertIndex([
        peaceRelation('gp1', 'gp2', 50, level: RelationLevel.neutral),
      ])..upsert('gp1', 'gp2', grantAidRelationUpdater('gp1', 'gp2', 2));
      final result = index.toList();
      expect(result.length, 1);
      expect(result[0].score, 55);
      expect(result[0].lastInteractionTurn, 2);
    });

    test('creates a new relation seeded from neutral + 5', () {
      final index = RelationUpsertIndex(const [])
        ..upsert('gp1', 'minor1', grantAidRelationUpdater('gp1', 'minor1', 4));
      final relations = index.toList();
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 5);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 5));
      expect(rel.lastInteractionTurn, 4);
    });
  });

  group('subsidyBoostRelationUpdater via RelationUpsertIndex', () {
    test('updates existing relation when pair already present', () {
      final index = RelationUpsertIndex([
        peaceRelation('gp1', 'gp2', 60, level: RelationLevel.friendly),
      ])..upsert(
        'gp1',
        'gp2',
        subsidyBoostRelationUpdater('gp1', 'gp2', 10, 3),
      );
      final result = index.toList();
      expect(result.length, 1);
      expect(result[0].score, 70);
      expect(result[0].lastInteractionTurn, 3);
    });

    test('creates a new relation seeded from neutral + boost', () {
      final index = RelationUpsertIndex(const [])
        ..upsert(
          'gp1',
          'tribe1',
          subsidyBoostRelationUpdater('gp1', 'tribe1', 6, 8),
        );
      final relations = index.toList();
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.score, relationScoreNeutral + 6);
      expect(rel.level, scoreToLevel(relationScoreNeutral + 6));
      expect(rel.lastInteractionTurn, 8);
    });
  });

  group('canonicalPairIds', () {
    test('orders ids canonically regardless of argument order', () {
      final a = canonicalPairIds('gp2', 'gp1');
      final b = canonicalPairIds('gp1', 'gp2');
      expect(a, b);
    });
  });

  group('warStateRelationUpdater via RelationUpsertIndex', () {
    test('positive: creates a hostile at-war relation for a new pair', () {
      final index = RelationUpsertIndex(const [])
        ..upsert('gp1', 'gp2', warStateRelationUpdater('gp1', 'gp2', 2));
      final relations = index.toList();
      expect(relations, hasLength(1));
      final rel = relations.single;
      expect(rel.state, RelationState.atWar);
      expect(rel.level, RelationLevel.hostile);
      expect(rel.sinceTurn, 2);
      expect(rel.formalAlliance, isFalse);
    });

    test('positive: transitioning an allied pair to war drops formalAlliance', () {
      const allied = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        level: RelationLevel.allied,
        formalAlliance: true,
      );
      final index = RelationUpsertIndex(const [allied])
        ..upsert('gp1', 'gp2', warStateRelationUpdater('gp1', 'gp2', 5));
      final rel = index.toList().single;
      expect(rel.state, RelationState.atWar);
      expect(rel.formalAlliance, isFalse);
    });

    test('negative: peace updater requires an existing relation', () {
      expect(
        () => peaceRelationUpdater('gp1', 'gp2', 1)(null),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('RelationUpsertIndex', () {
    test('positive: updates an existing pair in place (canonical order)', () {
      final index = RelationUpsertIndex([rel('gp1', 'gp2', 40)]);
      index.upsert('gp2', 'gp1', (e) => e!.copyWith(score: 88));
      final result = index.toList();
      expect(result.length, 1);
      expect(result.single.score, 88);
    });

    test('positive: appends a new pair and reuses its index on later upserts', () {
      final index = RelationUpsertIndex([rel('gp1', 'gp2', 40)]);
      index.upsert('gp3', 'gp4', (e) {
        expect(e, isNull);
        return rel('gp3', 'gp4', 10);
      });
      index.upsert('gp3', 'gp4', (e) {
        expect(e, isNotNull);
        return e!.copyWith(score: 20);
      });
      final result = index.toList();
      expect(result.length, 2);
      expect(getRelationFromList(result, 'gp3', 'gp4')?.score, 20);
    });

    test('positive: matches sequential upsertRelation results', () {
      final start = [rel('a', 'b', 30), rel('c', 'd', 60)];

      var sequential = upsertRelation(
        start,
        'a',
        'b',
        (e) => e!.copyWith(score: e.score + 5),
      );
      sequential = upsertRelation(
        sequential,
        'e',
        'f',
        (e) => rel('e', 'f', 70),
      );
      sequential = upsertRelation(
        sequential,
        'c',
        'd',
        (e) => e!.copyWith(score: e.score - 10),
      );

      final index = RelationUpsertIndex(start)
        ..upsert('a', 'b', (e) => e!.copyWith(score: e.score + 5))
        ..upsert('e', 'f', (e) => rel('e', 'f', 70))
        ..upsert('c', 'd', (e) => e!.copyWith(score: e.score - 10));
      final batched = index.toList();

      expect(batched.length, sequential.length);
      for (var i = 0; i < sequential.length; i++) {
        expect(batched[i].factionId1, sequential[i].factionId1);
        expect(batched[i].factionId2, sequential[i].factionId2);
        expect(batched[i].score, sequential[i].score);
      }
    });

    test('negative: empty start list appends new relations only', () {
      final index = RelationUpsertIndex(const [])
        ..upsert('x', 'y', (e) {
          expect(e, isNull);
          return rel('x', 'y', 50);
        });
      expect(index.length, 1);
      expect(index.toList().single.score, 50);
    });

    test('negative: toList returns a defensive copy (no shared mutation)', () {
      final index = RelationUpsertIndex([rel('a', 'b', 50)]);
      final snapshot = index.toList();
      index.upsert('a', 'b', (e) => e!.copyWith(score: 99));
      expect(snapshot.single.score, 50);
      expect(index.toList().single.score, 99);
    });
  });
}
