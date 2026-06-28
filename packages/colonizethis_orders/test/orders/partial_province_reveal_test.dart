import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/partial_province_reveal.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('partiallyRevealedPrefixedProvinceIdsForPlayer', () {
    test(
      'includes prefixed province id when land tiles mix unknown and known',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final game = TestFixtures.minimalGame(
          id: 'g1',
          players: [Player(id: playerId, displayName: 'GP', isHuman: true)],
          oldWorld: const RegionData(provinces: [], units: []),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['$ow|p1|0|0', '$ow|p1|0|1'],
            },
          },
        );
        final view = PlayerView(
          playerId: playerId,
          player: Player(id: playerId, displayName: 'GP', isHuman: true),
          ownUnitsById: const {},
          provincesById: const {},
          visibilityByTile: {
            '$ow|p1|0|0': VisibilityLevel.unknown,
            '$ow|p1|0|1': VisibilityLevel.fogged,
          },
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final ids = partiallyRevealedPrefixedProvinceIdsForPlayer(
          game: game,
          view: view,
        );
        expect(ids, {'$ow|p1'});
      },
    );

    test('excludes unprefixed province keys and uniform visibility', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [Player(id: playerId, displayName: 'GP', isHuman: true)],
        oldWorld: const RegionData(provinces: [], units: []),
        tileKeysByRegionAndProvince: {
          ow: {
            'p1': ['$ow|p1|0|0'],
            '$ow|p2': ['$ow|p2|0|0', '$ow|p2|0|1'],
          },
        },
      );
      final view = PlayerView(
        playerId: playerId,
        player: Player(id: playerId, displayName: 'GP', isHuman: true),
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: {
          '$ow|p2|0|0': VisibilityLevel.fogged,
          '$ow|p2|0|1': VisibilityLevel.fullyVisible,
        },
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final ids = partiallyRevealedPrefixedProvinceIdsForPlayer(
        game: game,
        view: view,
      );
      expect(ids, isEmpty);
    });

    test(
      'partial reveal ids resolve via provincesById to same set as allProvinces filter',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1, p2], units: const []),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['$ow|p1|0|0', '$ow|p1|0|1'],
              '$ow|p2': ['$ow|p2|0|0'],
            },
          },
          playerVisibilityByTile: {
            playerId: {
              '$ow|p1|0|0': 'unknown',
              '$ow|p1|0|1': 'fogged',
              '$ow|p2|0|0': 'fogged',
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: true),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final cache = partiallyRevealedPrefixedProvinceIdsForPlayer(
          game: game,
          view: view,
        );
        final legacy = allProvinces(game.worldState)
            .where((p) => cache.contains(p.id))
            .map((p) => p.id)
            .toList()
          ..sort();
        final optimized = <String>[];
        for (final id in cache) {
          final p =
              view.provincesById[id] ?? game.worldState.tryGetProvince(id);
          if (p != null) {
            optimized.add(p.id);
          }
        }
        optimized.sort();
        expect(cache, isNotEmpty);
        expect(optimized, legacy);
      },
    );
  });

  group('sortedProvincesForPartialRevealPrefixedIds', () {
    test('returns empty list without scanning when id set is empty', () {
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [Player(id: 'p1', displayName: 'P', isHuman: true)],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|a',
              regionId: 'oldWorld',
              displayName: 'A',
              ownerId: 'p1',
            ),
          ],
          units: const [],
        ),
      );
      final view = buildPlayerView(game, const MapTopology(), 'p1');
      expect(
        sortedProvincesForPartialRevealPrefixedIds(
          view: view,
          partiallyRevealedPrefixedProvinceIds: const {},
        ),
        isEmpty,
      );
    });

    test('returns matching provinces sorted by id', () {
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [Player(id: 'p1', displayName: 'P', isHuman: true)],
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$ow|z',
              regionId: ow,
              displayName: 'Z',
              ownerId: 'p1',
            ),
            Province(
              id: '$ow|m',
              regionId: ow,
              displayName: 'M',
              ownerId: 'p1',
            ),
            Province(
              id: '$ow|skip',
              regionId: ow,
              displayName: 'S',
              ownerId: 'p1',
            ),
          ],
          units: const [],
        ),
      );
      final view = buildPlayerView(game, const MapTopology(), 'p1');
      final sorted = sortedProvincesForPartialRevealPrefixedIds(
        view: view,
        partiallyRevealedPrefixedProvinceIds: {'$ow|z', '$ow|m'},
      );
      expect(sorted.map((p) => p.id).toList(), ['$ow|m', '$ow|z']);
    });
  });
}
