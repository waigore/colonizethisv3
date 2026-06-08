import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('build_improvement returns only controlled tiles with resources', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileWithResource = 'oldWorld|p1|0|0';
      const tileWithoutResource = 'oldWorld|p1|1|0';
      const foreignTileWithResource = 'oldWorld|p2|0|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileWithResource,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'other'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [tileWithResource, tileWithoutResource],
              '$ow|p2': [foreignTileWithResource],
            },
          },
          resourceByTileKey: {
            tileWithResource: 'grain',
            foreignTileWithResource: 'iron',
          },
          // Set up visibility for the player's provinces (fully visible)
          playerVisibilityByTile: {
            playerId: {
              tileWithResource: 'fullyVisible',
              tileWithoutResource: 'fullyVisible',
              foreignTileWithResource: 'fullyVisible',
            },
          },
          // Set up tile state with improvement level for the tile
          tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            // Need lumber and cast iron for build_improvement
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
          Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
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

      // Only tileWithResource (owned province, has resource) should be valid
      expect(valid.contains(tileWithResource), isTrue);
      // tileWithoutResource has no resource
      expect(valid.contains(tileWithoutResource), isFalse);
      // foreignTileWithResource is in unowned province
      expect(valid.contains(foreignTileWithResource), isFalse);
    });

    test('build_improvement excludes owned mineral tile until prospected; '
        'includes after prospected', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const grainTile = 'oldWorld|p1|0|0';
      const ironTile = 'oldWorld|p1|1|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: grainTile,
      );
      WorldState worldForProspected(Map<String, Set<String>> prospected) {
        return WorldState(
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
              '$ow|p1': [grainTile, ironTile],
            },
          },
          resourceByTileKey: {grainTile: 'grain', ironTile: 'iron'},
          playerVisibilityByTile: {
            playerId: {grainTile: 'fullyVisible', ironTile: 'fullyVisible'},
          },
          tileState: TileMapState(
            improvementByTile: {grainTile: 0, ironTile: 0},
          ),
          playerProspectedTiles: prospected,
        );
      }

      final topology = const MapTopology(nodes: [], edges: []);
      final stockpile = Stockpile(quantities: {'lumber': 10, 'castIron': 10});

      final gameUnprospected = Game(
        id: 'g1',
        worldState: worldForProspected(const {}),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: stockpile,
          ),
        ],
      );
      final viewUnprospected = buildPlayerView(
        gameUnprospected,
        topology,
        playerId,
      );
      final validUnprospected = getValidWorkOrderTileKeysWithVisibility(
        game: gameUnprospected,
        topology: topology,
        view: viewUnprospected,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );
      expect(validUnprospected.contains(grainTile), isTrue);
      expect(validUnprospected.contains(ironTile), isFalse);

      final gameProspected = Game(
        id: 'g2',
        worldState: worldForProspected({
          playerId: {ironTile},
        }),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: stockpile,
          ),
        ],
      );
      final viewProspected = buildPlayerView(
        gameProspected,
        topology,
        playerId,
      );
      final validProspected = getValidWorkOrderTileKeysWithVisibility(
        game: gameProspected,
        topology: topology,
        view: viewProspected,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );
      expect(validProspected.contains(grainTile), isTrue);
      expect(validProspected.contains(ironTile), isTrue);
    });

    test('build_improvement includes purchased tiles with resources', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const purchasedTileWithResource = 'oldWorld|p2|0|0';
      const unpurchasedTileWithResource = 'oldWorld|p2|1|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
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
              Province(id: '$ow|p2', regionId: ow, ownerId: 'minor1'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|p2': [
                purchasedTileWithResource,
                unpurchasedTileWithResource,
              ],
            },
          },
          resourceByTileKey: {
            purchasedTileWithResource: 'grain',
            unpurchasedTileWithResource: 'grain',
          },
          purchasedTilesByTileKey: {
            purchasedTileWithResource: playerId,
            // unpurchasedTileWithResource not purchased
          },
          playerVisibilityByTile: {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              purchasedTileWithResource: 'fullyVisible',
              unpurchasedTileWithResource: 'fullyVisible',
            },
          },
          tileState: TileMapState(
            improvementByTile: {purchasedTileWithResource: 0},
          ),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
        ],
        minorNations: [MinorNation(id: 'minor1', displayName: 'Minor')],
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

      // Purchased tile should be valid
      expect(valid.contains(purchasedTileWithResource), isTrue);
      // Unpurchased tile should not be valid
      expect(valid.contains(unpurchasedTileWithResource), isFalse);
    });

    test('build_improvement excludes sea zone tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const landTile = 'oldWorld|p1|0|0';
      // Sea zone tiles use just the sea zone id as province key (not prefixed)
      const seaZoneId = 's1';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: landTile,
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
              '$ow|p1': [landTile],
              // Sea zone uses non-prefixed id
              seaZoneId: ['$ow|$seaZoneId|0|0'],
            },
          },
          resourceByTileKey: {
            landTile: 'grain',
            '$ow|$seaZoneId|0|0': 'fish', // Hypothetical sea resource
          },
          playerVisibilityByTile: {
            playerId: {
              landTile: 'fullyVisible',
              '$ow|$seaZoneId|0|0': 'fullyVisible',
            },
          },
          tileState: TileMapState(improvementByTile: {landTile: 0}),
        ),
        players: [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
          ),
        ],
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

      // Only land tile should be valid
      expect(valid.contains(landTile), isTrue);
      // Sea zone tile should be excluded even if it has resource
      expect(valid.contains('$ow|$seaZoneId|0|0'), isFalse);
    });
  });
}
