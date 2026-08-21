import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

    test(
      'positive: withRelationUpserts is for relations-only single-pass commits',
      () {
        // Document eligible path: trade-deal boosts / first-contact style
        // passes that only mutate diplomacyRelations (Refs #4037).
        final game = relationsOnlyGame(relations: [rel('a', 'b', 50)]);
        final next = withRelationUpserts(game, (index) {
          index.upsert('a', 'b', grantAidRelationUpdater('a', 'b', 1));
        });
        expect(getRelation(next, 'a', 'b')?.score, 55);
        expect(next.players, same(game.players));
      },
    );

    test(
      'negative: mid-order multi-field commits keep explicit RelationUpsertIndex',
      () {
        // Grant-aid interleaves treasury debit with relation upserts; those
        // sites must NOT wrap the whole order loop in withRelationUpserts.
        final game = relationsOnlyGame(relations: [rel('gp1', 'gp2', 40)]);
        final index = RelationUpsertIndex(game.diplomacyRelations)
          ..upsert('gp1', 'gp2', (e) => e!.copyWith(score: 41));
        final next = game.copyWith(
          players: game.players,
          diplomacyRelations: committedRelations(index),
        );
        expect(getRelation(next, 'gp1', 'gp2')?.score, 41);
        expect(next.players, same(game.players));
      },
    );

    test('negative: committedRelations defensive copy is not live-mutated', () {
      final index = RelationUpsertIndex([rel('a', 'b', 50)]);
      final list = committedRelations(index);
      index.upsert('a', 'b', (e) => e!.copyWith(score: 11));
      expect(list.single.score, 50);
    });
  });
}
