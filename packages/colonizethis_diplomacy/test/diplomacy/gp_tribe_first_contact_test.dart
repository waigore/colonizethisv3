import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _ow = 'oldWorld';
const _nw = 'newWorld';

Game _gameWithoutGpTribeRelation({Map<String, Map<String, List<String>>>? tileKeys}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$_nw|t1',
            regionId: _nw,
            ownerId: 'tribe1',
            displayName: 'Maya Capital',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {'$_nw|t1|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: tileKeys ??
          {
            _nw: {
              '$_nw|t1': ['$_nw|t1|0|0'],
            },
          },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
    ],
    tribes: const [
      Tribe(
        id: 'tribe1',
        displayName: 'Maya',
        capitalProvinceId: '$_nw|t1',
      ),
    ],
    diplomacyRelations: const [],
  );
}

const _topology = MapTopology(nodes: [], edges: []);

void main() {
  suppressLogsForTests();

  group('applyGpTribeFirstContactRelations', () {
    test('creates AT_PEACE score-50 relation for discovered tribe', () {
      final game = _gameWithoutGpTribeRelation();
      final view = buildPlayerView(game, _topology, 'gp1');

      final result = applyGpTribeFirstContactRelations(
        game: game,
        gpId: 'gp1',
        view: view,
        topology: _topology,
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
      final game = _gameWithoutGpTribeRelation();
      final view = buildPlayerView(game, _topology, 'gp1');

      final first = applyGpTribeFirstContactRelations(
        game: game,
        gpId: 'gp1',
        view: view,
        topology: _topology,
      );
      final second = applyGpTribeFirstContactRelations(
        game: first.game,
        gpId: 'gp1',
        view: view,
        topology: _topology,
      );

      expect(second.newlyContactedTribeIds, isEmpty);
      expect(second.game.diplomacyRelations.length, 1);
    });

    test('negative: undiscovered tribe gets no relation', () {
      final game = _gameWithoutGpTribeRelation();
      final view = buildPlayerView(game, _topology, 'gp1');

      final hiddenGame = game.copyWith(
        worldState: game.worldState.copyWith(
          playerVisibilityByTile: const {},
        ),
      );
      final hiddenView = buildPlayerView(hiddenGame, _topology, 'gp1');

      final result = applyGpTribeFirstContactRelations(
        game: hiddenGame,
        gpId: 'gp1',
        view: hiddenView,
        topology: _topology,
      );

      expect(result.newlyContactedTribeIds, isEmpty);
      expect(result.game.diplomacyRelations, isEmpty);
    });
  });
}
