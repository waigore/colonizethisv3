import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test('build_improvement returns only controlled tiles with resources', () {
      final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
      final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
      final p1 = ValidWorkTilesTestSupport.provinceId('p1');
      final p2 = ValidWorkTilesTestSupport.provinceId('p2');

      final unit = ValidWorkTilesTestSupport.builderUnit(
        locationProvinceId: p1,
        tileKey: tileWithResource,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p1,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: ValidWorkTilesTestSupport.playerId,
              ),
              Province(
                id: p2,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: 'other',
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              p1: [tileWithResource, tileWithoutResource],
              p2: [foreignTileWithResource],
            },
          ),
          resourceByTileKey: {
            tileWithResource: 'grain',
            foreignTileWithResource: 'iron',
          },
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              tileWithResource: 'fullyVisible',
              tileWithoutResource: 'fullyVisible',
              foreignTileWithResource: 'fullyVisible',
            },
          },
          tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
        ),
        players: [
          ValidWorkTilesTestSupport.playerWithBuildStockpile(),
          const Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
      );
      final topology = ValidWorkTilesTestSupport.emptyTopology;
      final view = buildPlayerView(
        game,
        topology,
        ValidWorkTilesTestSupport.playerId,
      );

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      expect(valid.contains(tileWithResource), isTrue);
      expect(valid.contains(tileWithoutResource), isFalse);
      expect(valid.contains(foreignTileWithResource), isFalse);
    });

    test('build_improvement excludes owned mineral tile until prospected; '
        'includes after prospected', () {
      final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
      final p1 = ValidWorkTilesTestSupport.provinceId('p1');

      final unit = ValidWorkTilesTestSupport.builderUnit(
        locationProvinceId: p1,
        tileKey: grainTile,
      );
      WorldState worldForProspected(Map<String, Set<String>> prospected) {
        return WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p1,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: ValidWorkTilesTestSupport.playerId,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {p1: [grainTile, ironTile]},
          ),
          resourceByTileKey: {grainTile: 'grain', ironTile: 'iron'},
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              grainTile: 'fullyVisible',
              ironTile: 'fullyVisible',
            },
          },
          tileState: TileMapState(
            improvementByTile: {grainTile: 0, ironTile: 0},
          ),
          playerProspectedTiles: prospected,
        );
      }

      final topology = ValidWorkTilesTestSupport.emptyTopology;
      final player = ValidWorkTilesTestSupport.playerWithBuildStockpile();

      final gameUnprospected = Game(
        id: 'g1',
        worldState: worldForProspected(const {}),
        players: [player],
      );
      final viewUnprospected = buildPlayerView(
        gameUnprospected,
        topology,
        ValidWorkTilesTestSupport.playerId,
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
          ValidWorkTilesTestSupport.playerId: {ironTile},
        }),
        players: [player],
      );
      final viewProspected = buildPlayerView(
        gameProspected,
        topology,
        ValidWorkTilesTestSupport.playerId,
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
      final purchasedTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
      final unpurchasedTileWithResource =
          ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
      final p1 = ValidWorkTilesTestSupport.provinceId('p1');
      final p2 = ValidWorkTilesTestSupport.provinceId('p2');
      final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);

      final unit = ValidWorkTilesTestSupport.builderUnit(
        locationProvinceId: p1,
        tileKey: ownTile,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p1,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: ValidWorkTilesTestSupport.playerId,
              ),
              Province(
                id: p2,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: 'minor1',
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {
              p1: [ownTile],
              p2: [purchasedTileWithResource, unpurchasedTileWithResource],
            },
          ),
          resourceByTileKey: {
            purchasedTileWithResource: 'grain',
            unpurchasedTileWithResource: 'grain',
          },
          purchasedTilesByTileKey: {
            purchasedTileWithResource: ValidWorkTilesTestSupport.playerId,
          },
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              ownTile: 'fullyVisible',
              purchasedTileWithResource: 'fullyVisible',
              unpurchasedTileWithResource: 'fullyVisible',
            },
          },
          tileState: TileMapState(
            improvementByTile: {purchasedTileWithResource: 0},
          ),
        ),
        players: [ValidWorkTilesTestSupport.playerWithBuildStockpile()],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final topology = ValidWorkTilesTestSupport.emptyTopology;
      final view = buildPlayerView(
        game,
        topology,
        ValidWorkTilesTestSupport.playerId,
      );

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      expect(valid.contains(purchasedTileWithResource), isTrue);
      expect(valid.contains(unpurchasedTileWithResource), isFalse);
    });

    test('build_improvement excludes sea zone tiles', () {
      final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
      const seaZoneId = 's1';
      final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
      final p1 = ValidWorkTilesTestSupport.provinceId('p1');

      final unit = ValidWorkTilesTestSupport.builderUnit(
        locationProvinceId: p1,
        tileKey: landTile,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: p1,
                regionId: ValidWorkTilesTestSupport.ow,
                ownerId: ValidWorkTilesTestSupport.playerId,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ValidWorkTilesTestSupport.ow: {
              p1: [landTile],
              seaZoneId: [seaTile],
            },
          },
          resourceByTileKey: {
            landTile: 'grain',
            seaTile: 'fish',
          },
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              landTile: 'fullyVisible',
              seaTile: 'fullyVisible',
            },
          },
          tileState: TileMapState(improvementByTile: {landTile: 0}),
        ),
        players: [ValidWorkTilesTestSupport.playerWithBuildStockpile()],
      );
      final topology = ValidWorkTilesTestSupport.emptyTopology;
      final view = buildPlayerView(
        game,
        topology,
        ValidWorkTilesTestSupport.playerId,
      );

      final valid = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'u1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: const Orders(),
      );

      expect(valid.contains(landTile), isTrue);
      expect(valid.contains(seaTile), isFalse);
    });
  });
}
