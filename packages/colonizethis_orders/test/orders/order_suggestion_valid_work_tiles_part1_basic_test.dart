import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('returns empty for unknown unit id', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        oldWorld: const RegionData(provinces: [], units: []),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final valid = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'no-such-unit',
        kWorkTargetExplore,
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty when workTarget not allowed for unit type', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
          units: [unit],
        ),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final valid = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'u1',
        kWorkTargetBuildImprovement,
        const Orders(),
      );
      expect(valid, isEmpty);
    });

    test('returns empty for unknown unit id with visibility', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        oldWorld: const RegionData(provinces: [], units: []),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);
      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'no-such-unit',
        workTarget: kWorkTargetExplore,
        currentOrders: const Orders(),
      );
      expect(valid, isEmpty);
    });

    test(
      'returns empty when workTarget not allowed for unit type with visibility',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: 'oldWorld|p1|0|0',
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|p1': ['oldWorld|p1|0|0'],
              },
            },
          ),
          players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
        );
        final topology = const MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, playerId);
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetBuildImprovement,
          currentOrders: const Orders(),
        );
        expect(valid, isEmpty);
      },
    );

    test('filters by visibility before order engine validation', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final unit = Unit(
        id: 'u1',
        type: 'Colonist',
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|p2': ['oldWorld|p2|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
      );
      final topology = const MapTopology(nodes: [], edges: []);

      final viewWithFullVisibility = buildPlayerView(game, topology, playerId);

      final validWithVisibility = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: viewWithFullVisibility,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      final validWithoutVisibility = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'u1',
        kWorkTargetBuildImprovement,
        const Orders(),
      );

      expect(validWithVisibility.length, validWithoutVisibility.length);
    });
  });
}
