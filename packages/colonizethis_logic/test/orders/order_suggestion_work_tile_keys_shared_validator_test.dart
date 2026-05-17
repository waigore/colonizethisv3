import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getValidWorkOrderTileKeysWithVisibility shared validator', () {
    test('sharedCandidateValidator matches default path for same inputs', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p1|1|0';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileA,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [b1]),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileA, tileB],
          },
        },
        resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
        tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);
      const orders = Orders();

      final baseline = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
      );

      final shared = buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: orders,
      );

      final withShared = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
        sharedCandidateValidator: shared,
      );

      expect(withShared, equals(baseline));
    });

    test('playerOwnedProvinceIds matches default path for same inputs', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p1|1|0';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileA,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [b1]),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileA, tileB],
          },
        },
        resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
        tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);
      const orders = Orders();
      final ownedIds = <String>{
        for (final e in view.provincesById.entries)
          if (e.value.ownerId == playerId) e.key,
      };

      final baseline = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
      );

      final withOwnedIds = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
        playerOwnedProvinceIds: ownedIds,
      );

      expect(withOwnedIds, equals(baseline));
    });

    test('optional unitsById matches default path', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p1|1|0';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileA,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [b1]),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileA, tileB],
          },
        },
        resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
        tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = const MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, playerId);
      const orders = Orders();
      final unitsById = unitsByIdFromWorld(game.worldState);

      final baseline = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
      );

      final withUnitsById = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'b1',
        workTarget: kWorkTargetBuildImprovement,
        currentOrders: orders,
        unitsById: unitsById,
      );

      expect(withUnitsById, equals(baseline));
    });
  });

  group('getValidWorkOrderTileKeys PlayerView reuse', () {
    test('matches prior behavior for builder improvement tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p1|1|0';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileA,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [b1]),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileA, tileB],
          },
        },
        resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
        tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = const MapTopology(nodes: [], edges: []);

      final keys = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'b1',
        kWorkTargetBuildImprovement,
        const Orders(),
      );

      expect(keys, contains(tileA));
      expect(keys, contains(tileB));
    });

    test('shared view and validator matches default path', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p1|1|0';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
        tileKey: tileA,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [b1]),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileA, tileB],
          },
        },
        resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
        tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = const MapTopology(nodes: [], edges: []);
      const orders = Orders();

      final baseline = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'b1',
        kWorkTargetBuildImprovement,
        orders,
      );

      final view = buildPlayerView(game, topology, playerId);
      final membership = DiplomacyFactionMembership.from(game);
      final unitsById = unitsByIdFromWorld(game.worldState);
      final ownedIds = <String>{
        for (final e in view.provincesById.entries)
          if (e.value.ownerId == playerId) e.key,
      };
      final shared = buildIncrementalCandidateValidator(
        game: game,
        topology: topology,
        playerId: playerId,
        baseOrders: orders,
        view: view,
        unitsById: unitsById,
        factionMembership: membership,
      );

      final withShared = getValidWorkOrderTileKeys(
        game,
        topology,
        playerId,
        'b1',
        kWorkTargetBuildImprovement,
        orders,
        view: view,
        unitsById: unitsById,
        factionMembership: membership,
        sharedCandidateValidator: shared,
        playerOwnedProvinceIds: ownedIds,
      );

      expect(withShared, equals(baseline));
    });
  });
}
