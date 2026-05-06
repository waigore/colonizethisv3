import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('getAvailableWorkTargetsForUnit (Refs #2133)', () {
    test(
      'pending draft work short-circuits availability with zero engine probes',
      () {
        setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
        addTearDown(
          () =>
              setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
        );

        const playerId = 'gp1';
        const ow = 'oldWorld';
        const explorerId = 'E1';
        final player = const Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          treasury: 5000,
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final explorer = Unit(
          id: explorerId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: p1.id,
          tileKey: '$ow|p1|0|0',
          status: UnitStatus.idle,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [explorer]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            playerId: {'$ow|p1|0|0': 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            ow: {
              p1.id: ['$ow|p1|0|0'],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [],
          tribes: const [],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final pending = WorkOrder(
          unitId: explorerId,
          target: kWorkTargetExplore,
          targetTileKey: '$ow|p1|0|0',
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            playerId: [pending],
          },
        );
        final view = buildPlayerView(game, topology, playerId);

        final availability = getAvailableWorkTargetsForUnit(
          view: view,
          game: game,
          topology: topology,
          currentOrders: orders,
          unitId: explorerId,
        );
        expect(availability.assignable, isFalse);
        expect(availability.blockedReason, 'pending_draft_work_order');
        expect(availability.validTileKeysByTarget, isEmpty);
        expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
      },
    );

    test('getValidWorkOrderTileKeysWithVisibility skips prospect when pending '
        'explore exists (zero probes)', () {
      setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
      addTearDown(
        () => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
      );

      const playerId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      final tiles = List.generate(120, (i) => '$ow|p1|$i|0');

      final explorer = Unit(
        id: 'E1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: provinceId,
        tileKey: tiles.first,
        status: UnitStatus.idle,
      );

      final vis = <String, String>{for (final t in tiles) t: 'fogged'};

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: playerId),
          ],
          units: [explorer],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: {playerId: vis},
        tileKeysByRegionAndProvince: {
          ow: {provinceId: tiles},
        },
        resourceByTileKey: {for (final t in tiles) t: 'coal'},
        playerProspectedTiles: const {},
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: playerId, displayName: 'Human', isHuman: true),
        ],
        minorNations: const [],
        tribes: const [],
      );

      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      final view = buildPlayerView(game, topology, playerId);
      final orders = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'E1',
              target: kWorkTargetExplore,
              targetTileKey: tiles.first,
            ),
          ],
        },
      );

      final validProspect = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'E1',
        workTarget: kWorkTargetProspect,
        currentOrders: orders,
      );

      expect(validProspect, isEmpty);
      expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
    });
  });
}
