import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/player_view_test_support.dart';

/// Panel intel gate pins for `provincePanelShowsFullTileDerivedIntel` (Refs #4125).
void main() {
  group('provincePanelShowsFullTileDerivedIntel', () {
    test('own province always shows full intel', () {
      final game = TestFixtures.minimalGame();
      final view = panelIntelViewWith(
        provincesById: const {
          'oldWorld|a': Province(
            id: 'oldWorld|a',
            regionId: 'oldWorld',
            ownerId: 'p1',
          ),
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|a',
          provinceTileKeys: const ['t1'],
        ),
        isTrue,
      );
    });

    test('foreign province with own spy present shows full intel', () {
      final game = TestFixtures.minimalGame();
      final view = panelIntelViewWith(
        provincesById: const {
          'oldWorld|e': Province(
            id: 'oldWorld|e',
            regionId: 'oldWorld',
            ownerId: 'p2',
          ),
        },
        ownUnits: [playerViewSpy(id: 's1', ownerId: 'p1', loc: 'oldWorld|e')],
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1'],
        ),
        isTrue,
      );
    });

    test(
      'foreign province with an active spy-reveal timer shows full intel',
      () {
        final game = TestFixtures.minimalGame(
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          spyRevealTurnsByPlayer: const {
            'p1': {'oldWorld|e': 2},
          },
        );
        final view = panelIntelViewWith(
          provincesById: const {
            'oldWorld|e': Province(
              id: 'oldWorld|e',
              regionId: 'oldWorld',
              ownerId: 'p2',
            ),
          },
        );
        expect(
          provincePanelShowsFullTileDerivedIntel(
            game: game,
            view: view,
            humanPlayerId: 'p1',
            provinceId: 'oldWorld|e',
            provinceTileKeys: const ['t1'],
          ),
          isTrue,
        );
      },
    );

    test('foreign province is full only when every tile is fully visible', () {
      final game = TestFixtures.minimalGame();
      const province = Province(
        id: 'oldWorld|e',
        regionId: 'oldWorld',
        ownerId: 'p2',
      );
      final fullView = panelIntelViewWith(
        provincesById: {'oldWorld|e': province},
        visibilityByTile: const {
          't1': VisibilityLevel.fullyVisible,
          't2': VisibilityLevel.fullyVisible,
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: fullView,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1', 't2'],
        ),
        isTrue,
      );

      final partialView = panelIntelViewWith(
        provincesById: {'oldWorld|e': province},
        visibilityByTile: const {
          't1': VisibilityLevel.fullyVisible,
          't2': VisibilityLevel.fogged,
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: partialView,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const ['t1', 't2'],
        ),
        isFalse,
      );
    });

    test('foreign province with no known tiles is not full intel', () {
      final game = TestFixtures.minimalGame();
      final view = panelIntelViewWith(
        provincesById: const {
          'oldWorld|e': Province(
            id: 'oldWorld|e',
            regionId: 'oldWorld',
            ownerId: 'p2',
          ),
        },
      );
      expect(
        provincePanelShowsFullTileDerivedIntel(
          game: game,
          view: view,
          humanPlayerId: 'p1',
          provinceId: 'oldWorld|e',
          provinceTileKeys: const [],
        ),
        isFalse,
      );
    });
  });
}
