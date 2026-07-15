import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('relation commit helpers (Refs #4028)', () {
    test('positive: withCommittedRelations replaces only diplomacyRelations', () {
      final game = relationsOnlyGame(
        relations: [rel('gp1', 'gp2', 40)],
      );
      final index = RelationUpsertIndex(game.diplomacyRelations)
        ..upsert('gp1', 'gp2', (e) => e!.copyWith(score: 77));
      final next = withCommittedRelations(game, index);
      expect(getRelation(next, 'gp1', 'gp2')?.score, 77);
      expect(next.players, same(game.players));
    });

    test('positive: withRelationUpserts builds index, mutates, and commits', () {
      final game = relationsOnlyGame(
        relations: [rel('gp1', 'gp2', 40)],
      );
      final next = withRelationUpserts(game, (index) {
        index.upsert('gp1', 'gp2', (e) => e!.copyWith(score: 55));
      });
      expect(getRelation(next, 'gp1', 'gp2')?.score, 55);
    });

    test('negative: committedRelations defensive copy is not live-mutated', () {
      final index = RelationUpsertIndex([rel('a', 'b', 50)]);
      final list = committedRelations(index);
      index.upsert('a', 'b', (e) => e!.copyWith(score: 11));
      expect(list.single.score, 50);
    });
  });
}
