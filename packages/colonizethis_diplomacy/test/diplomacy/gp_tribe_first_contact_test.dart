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

/// Old World coastal province sea-connected to an unrevealed New World tribe
/// colony, with **zero** New World tile visibility. Mirrors the colonial-intel
/// fixture in `order_suggestion_declare_war_colonial_discovery_test.dart`.
const _seaReachableTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|home',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|owSea',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|nwSea',
      regionId: 'newWorld',
      type: TopologyNodeType.seaZone,
    ),
    TopologyNode(
      id: 'newWorld|colony',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'oldWorld|home', id2: 'oldWorld|owSea'),
    TopologyEdge(id1: 'oldWorld|owSea', id2: 'newWorld|nwSea'),
    TopologyEdge(id1: 'newWorld|nwSea', id2: 'newWorld|colony'),
  ],
);

Game _seaReachableGameWithoutNwVisibility() {
  return Game(
    id: 'g_sea',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      playerVisibilityByTile: {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|home': ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
    diplomacyRelations: const [],
  );
}

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

    test('negative: game with no tribes returns empty result', () {
      final game = _gameWithoutGpTribeRelation();
      final view = buildPlayerView(game, _topology, 'gp1');
      final noTribes = game.copyWith(tribes: const []);

      final result = applyGpTribeFirstContactRelations(
        game: noTribes,
        gpId: 'gp1',
        view: view,
        topology: _topology,
      );

      expect(result.newlyContactedTribeIds, isEmpty);
      expect(identical(result.game, noTribes), isTrue);
    });

    test('negative: undiscovered tribe gets no relation', () {
      final game = _gameWithoutGpTribeRelation();

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

    test(
      'negative: sea-reachable tribe with zero NW visibility persists no relation (#3463)',
      () {
        final game = _seaReachableGameWithoutNwVisibility();
        final view = buildPlayerView(game, _seaReachableTopology, 'gp1');

        // Diplomatic targeting no longer sees the sea-reachable tribe: the
        // shared first-contact gate (relation or non-`unknown` tile visibility)
        // now governs the helper too (#3620).
        expect(
          knownDiplomaticTargetFactionIds(
            view: view,
            game: game,
            topology: _seaReachableTopology,
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
          topology: _seaReachableTopology,
        );

        expect(result.newlyContactedTribeIds, isEmpty);
        expect(result.game.diplomacyRelations, isEmpty);
      },
    );
  });

  group('discoveredTribeIdsForFirstContact', () {
    test('returns tribe when GP has non-unknown NW tile visibility', () {
      final game = _gameWithoutGpTribeRelation();
      final view = buildPlayerView(game, _topology, 'gp1');

      expect(
        discoveredTribeIdsForFirstContact(view: view, game: game),
        {'tribe1'},
      );
    });

    test('returns empty when NW tiles are unknown', () {
      final game = _gameWithoutGpTribeRelation().copyWith(
        worldState: _gameWithoutGpTribeRelation().worldState.copyWith(
          playerVisibilityByTile: const {},
        ),
      );
      final view = buildPlayerView(game, _topology, 'gp1');

      expect(
        discoveredTribeIdsForFirstContact(view: view, game: game),
        isEmpty,
      );
    });
  });
}
