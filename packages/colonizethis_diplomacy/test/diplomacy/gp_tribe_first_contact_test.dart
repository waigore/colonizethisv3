import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyGpTribeFirstContactRelations', () {
    test('creates AT_PEACE score-50 relation for discovered tribe', () {
      final game = gpTribeFirstContactGame();
      final view = buildPlayerView(game, gpTribeEmptyTopology, 'gp1');

      final result = applyGpTribeFirstContactRelations(
        game: game,
        gpId: 'gp1',
        view: view,
        topology: gpTribeEmptyTopology,
      );

      expect(result.newlyContactedTribeIds, ['tribe1']);
      final rel = getRelation(result.game, 'gp1', 'tribe1');
      expect(rel, isNotNull);
      expect(rel!.state, RelationState.atPeace);
      expect(rel.score, relationScoreNeutral);
      expect(rel.level, RelationLevel.neutral);
      expect(rel.sinceTurn, 3);
    });

    test('does not duplicate relation on second pass', () {
      final game = gpTribeFirstContactGame();
      final view = buildPlayerView(game, gpTribeEmptyTopology, 'gp1');

      final first = applyGpTribeFirstContactRelations(
        game: game,
        gpId: 'gp1',
        view: view,
        topology: gpTribeEmptyTopology,
      );
      final second = applyGpTribeFirstContactRelations(
        game: first.game,
        gpId: 'gp1',
        view: view,
        topology: gpTribeEmptyTopology,
      );

      expect(second.newlyContactedTribeIds, isEmpty);
      expect(second.game.diplomacyRelations.length, 1);
    });

    test('negative: game with no tribes returns empty result', () {
      final game = gpTribeFirstContactGame();
      final view = buildPlayerView(game, gpTribeEmptyTopology, 'gp1');
      final noTribes = game.copyWith(tribes: const []);

      final result = applyGpTribeFirstContactRelations(
        game: noTribes,
        gpId: 'gp1',
        view: view,
        topology: gpTribeEmptyTopology,
      );

      expect(result.newlyContactedTribeIds, isEmpty);
      expect(identical(result.game, noTribes), isTrue);
    });

    test('negative: undiscovered tribe gets no relation', () {
      final game = gpTribeFirstContactGame();

      final hiddenGame = game.copyWith(
        worldState: game.worldState.copyWith(
          playerVisibilityByTile: const {},
        ),
      );
      final hiddenView = buildPlayerView(hiddenGame, gpTribeEmptyTopology, 'gp1');

      final result = applyGpTribeFirstContactRelations(
        game: hiddenGame,
        gpId: 'gp1',
        view: hiddenView,
        topology: gpTribeEmptyTopology,
      );

      expect(result.newlyContactedTribeIds, isEmpty);
      expect(result.game.diplomacyRelations, isEmpty);
    });

    test(
      'negative: sea-reachable tribe with zero NW visibility persists no relation (#3463)',
      () {
        final game = gpTribeSeaReachableNoNwVisibilityGame();
        final view = buildPlayerView(game, gpTribeSeaReachableTopology, 'gp1');

        // Diplomatic targeting no longer sees the sea-reachable tribe: the
        // shared first-contact gate (relation or non-`unknown` tile visibility)
        // now governs the helper too (#3620).
        expect(
          knownDiplomaticTargetFactionIds(
            view: view,
            game: game,
            topology: gpTribeSeaReachableTopology,
          ),
          isNot(contains('tribe1')),
        );

        // Herald discovery is likewise narrowed to actual NW tile visibility.
        expect(
          discoveredTribeIdsForFirstContact(view: view, game: game),
          isEmpty,
        );

        final result = applyGpTribeFirstContactRelations(
          game: game,
          gpId: 'gp1',
          view: view,
          topology: gpTribeSeaReachableTopology,
        );

        expect(result.newlyContactedTribeIds, isEmpty);
        expect(result.game.diplomacyRelations, isEmpty);
      },
    );
  });

  group('discoveredTribeIdsForFirstContact', () {
    test('returns tribe when GP has non-unknown NW tile visibility', () {
      final game = gpTribeFirstContactGame();
      final view = buildPlayerView(game, gpTribeEmptyTopology, 'gp1');

      expect(
        discoveredTribeIdsForFirstContact(view: view, game: game),
        {'tribe1'},
      );
    });

    test('returns empty when NW tiles are unknown', () {
      final game = gpTribeFirstContactGame().copyWith(
        worldState: gpTribeFirstContactGame().worldState.copyWith(
          playerVisibilityByTile: const {},
        ),
      );
      final view = buildPlayerView(game, gpTribeEmptyTopology, 'gp1');

      expect(
        discoveredTribeIdsForFirstContact(view: view, game: game),
        isEmpty,
      );
    });
  });
}
