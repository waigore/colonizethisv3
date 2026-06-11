import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage for [RelationUpsertIndex], the per-phase amortized-O(1) relation
/// upsert accumulator (Refs #3419 step 5). The accumulator must produce results
/// identical to applying [upsertRelation] sequentially.
DiplomacyRelation _rel(String a, String b, int score) =>
    DiplomacyRelation(factionId1: a, factionId2: b, score: score);

void main() {
  group('RelationUpsertIndex', () {
    test('positive: updates an existing pair in place (canonical order)', () {
      final index = RelationUpsertIndex([_rel('gp1', 'gp2', 40)]);
      // Reversed argument order resolves to the same canonical pair.
      index.upsert('gp2', 'gp1', (e) => e!.copyWith(score: 88));
      final result = index.toList();
      expect(result.length, 1);
      expect(result.single.score, 88);
    });

    test('positive: appends a new pair and reuses its index on later upserts', () {
      final index = RelationUpsertIndex([_rel('gp1', 'gp2', 40)]);
      index.upsert('gp3', 'gp4', (e) {
        expect(e, isNull);
        return _rel('gp3', 'gp4', 10);
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
      final start = [_rel('a', 'b', 30), _rel('c', 'd', 60)];

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
        (e) => _rel('e', 'f', 70),
      );
      sequential = upsertRelation(
        sequential,
        'c',
        'd',
        (e) => e!.copyWith(score: e.score - 10),
      );

      final index = RelationUpsertIndex(start)
        ..upsert('a', 'b', (e) => e!.copyWith(score: e.score + 5))
        ..upsert('e', 'f', (e) => _rel('e', 'f', 70))
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
          return _rel('x', 'y', 50);
        });
      expect(index.length, 1);
      expect(index.toList().single.score, 50);
    });

    test('negative: toList returns a defensive copy (no shared mutation)', () {
      final index = RelationUpsertIndex([_rel('a', 'b', 50)]);
      final snapshot = index.toList();
      index.upsert('a', 'b', (e) => e!.copyWith(score: 99));
      // Earlier snapshot must not see the later mutation.
      expect(snapshot.single.score, 50);
      expect(index.toList().single.score, 99);
    });
  });
}

DiplomacyRelation? getRelationFromList(
  List<DiplomacyRelation> relations,
  String a,
  String b,
) {
  final key = pairKey(a, b);
  for (final r in relations) {
    if (pairKey(r.factionId1, r.factionId2) == key) return r;
  }
  return null;
}
