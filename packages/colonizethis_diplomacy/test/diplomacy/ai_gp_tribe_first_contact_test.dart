import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyAiGpTribeFirstContactRelations', () {
    test('AI GP with NW visibility gets AT_PEACE score-50 relation', () {
      final game = humanAndAiGpTribeVisibilityGame();

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: gpTribeEmptyTopology,
      );

      final rel = getRelation(next, 'gp2', 'tribe1');
      expect(rel, isNotNull);
      expect(rel!.state, RelationState.atPeace);
      expect(rel.score, relationScoreNeutral);
      expect(rel.level, RelationLevel.neutral);
      expect(rel.sinceTurn, 4);
    });

    test('human GP is skipped during turn resolution', () {
      final game = humanAndAiGpTribeVisibilityGame();

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: gpTribeEmptyTopology,
      );

      // Only the AI GP relation is created; the human relation/herald is left
      // for the app layer (`syncGpTribeFirstContact`).
      expect(getRelation(next, 'gp1', 'tribe1'), isNull);
      expect(next.diplomacyRelations.length, 1);
    });

    test('does not duplicate an existing AI GP relation on a second pass', () {
      final game = humanAndAiGpTribeVisibilityGame();

      final first = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: gpTribeEmptyTopology,
      );
      final second = applyAiGpTribeFirstContactRelations(
        game: first,
        topology: gpTribeEmptyTopology,
      );

      expect(second.diplomacyRelations.length, 1);
    });

    test('negative: AI GP with no NW tile visibility gets no relation', () {
      const nw = 'newWorld';
      const ow = 'oldWorld';
      final base = humanAndAiGpTribeVisibilityGame();
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          playerVisibilityByTile: const {
            'gp1': {'$nw|t1|0|0': 'fullyVisible'},
            'gp2': {'$ow|p2|0|0': 'fullyVisible'},
          },
        ),
      );

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: gpTribeEmptyTopology,
      );

      expect(getRelation(next, 'gp2', 'tribe1'), isNull);
      expect(next.diplomacyRelations, isEmpty);
    });

    test('negative: game with no tribes returns the same instance', () {
      final game = humanAndAiGpTribeVisibilityGame().copyWith(tribes: const []);

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: gpTribeEmptyTopology,
      );

      expect(identical(next, game), isTrue);
    });

    test(
      'observer mode: human GP flagged AI-controlled also gets a relation',
      () {
        final game = humanAndAiGpTribeVisibilityGame(
          aiControlByGpId: const {'gp1': true, 'gp2': true},
        );

        final next = applyAiGpTribeFirstContactRelations(
          game: game,
          topology: gpTribeEmptyTopology,
        );

        expect(getRelation(next, 'gp1', 'tribe1'), isNotNull);
        expect(getRelation(next, 'gp2', 'tribe1'), isNotNull);
        expect(next.diplomacyRelations.length, 2);
      },
    );
  });
}
