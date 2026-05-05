import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getAvailableWorkTargetsForUnit', () {
    test('short-circuits when unit already has pending work order', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const tileKey = '$ow|p1|0|0';

      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 500,
        workerPool: const WorkerPool(peasants: 1),
      );

      final province = Province(
        id: provinceId,
        regionId: ow,
        ownerId: playerId,
      );

      final builder = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: playerId,
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );

      final existingOrder = WorkOrder(
        unitId: builder.id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: tileKey,
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [province], units: [builder]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            provinceId: [tileKey],
          },
        },
        resourceByTileKey: {tileKey: 'grain'},
        tileState: const TileMapState(improvementByTile: {}),
      );

      final game = Game(id: 'g1', worldState: world, players: [player]);

      final topology = const MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );

      final view = buildPlayerView(game, topology, playerId);
      final currentOrders = Orders(
        workOrdersByPlayerId: {
          playerId: [existingOrder],
        },
      );

      final availability = getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: currentOrders,
        unitId: builder.id,
      );

      expect(availability.assignable, isFalse);
      expect(availability.validTileKeysByTarget, isEmpty);
      expect(
        availability.blockedReason,
        anyOf('unit_has_pending_work_order', 'unit_has_current_work'),
      );
    });

    test('returns targets when unit is idle and has valid tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const tileKnown = '$ow|p1|0|0';
      const tileUnknown = '$ow|p1|1|0';

      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 500,
        workerPool: const WorkerPool(peasants: 1),
      );

      final province = Province(
        id: provinceId,
        regionId: ow,
        ownerId: playerId,
      );

      final explorer = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: provinceId,
        tileKey: tileKnown,
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [province], units: [explorer]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKnown: 'fullyVisible', tileUnknown: 'unknown'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            provinceId: [tileKnown, tileUnknown],
          },
        },
      );

      final game = Game(id: 'g2', worldState: world, players: [player]);

      final topology = const MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );

      final view = buildPlayerView(game, topology, playerId);
      const currentOrders = Orders();

      final availability = getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: currentOrders,
        unitId: explorer.id,
      );

      expect(availability.assignable, isTrue);
      expect(availability.blockedReason, isNull);
      expect(
        availability.validTileKeysByTarget.keys,
        contains(kWorkTargetExplore),
      );
      final tilesForTarget =
          availability.validTileKeysByTarget[kWorkTargetExplore]!;
      expect(tilesForTarget, contains(tileKnown));
    });
  });
}
