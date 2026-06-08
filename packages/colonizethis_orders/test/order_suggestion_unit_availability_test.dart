import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  suppressLogsForTests();

  group('getAvailableWorkTargetsForUnit (Refs #2133)', () {
    test('pending draft work short-circuits with zero engine probes', () {
      setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
      addTearDown(
        () => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
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
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
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

      expect(
        getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: explorerId,
          workTarget: kWorkTargetExplore,
          currentOrders: orders,
        ),
        isEmpty,
      );
      expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
    });

    test(
      'pending draft: zero probes even with high-reveal world (issue #2133 scale)',
      () {
        setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
        addTearDown(
          () =>
              setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
        );

        const playerId = 'gp1';
        const ow = 'oldWorld';
        const explorerId = 'E1';
        const tribeId = 'tribe1';
        const partialProvinceCount = 20;
        const extraProvinceCount = 10;
        const tilesPerPartialProvince = 6;
        const tilesPerDenseProvince = 10;

        final player = const Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          treasury: 5000,
        );
        final provinces = <Province>[];
        final byProvince = <String, List<String>>{};
        final visibility = <String, String>{};

        for (var p = 0; p < partialProvinceCount; p++) {
          final provinceId = '$ow|partial$p';
          provinces.add(
            Province(id: provinceId, regionId: ow, ownerId: tribeId),
          );
          final tiles = <String>[];
          for (var t = 0; t < tilesPerPartialProvince; t++) {
            final tileKey = '$ow|partial$p|$t|0';
            tiles.add(tileKey);
            if (t == 0) {
              visibility[tileKey] = 'fogged';
            } else {
              visibility[tileKey] = 'unknown';
            }
          }
          byProvince[provinceId] = tiles;
        }

        for (var p = 0; p < extraProvinceCount; p++) {
          final provinceId = '$ow|dense$p';
          provinces.add(
            Province(id: provinceId, regionId: ow, ownerId: tribeId),
          );
          final tiles = <String>[];
          for (var t = 0; t < tilesPerDenseProvince; t++) {
            final tileKey = '$ow|dense$p|$t|0';
            tiles.add(tileKey);
            visibility[tileKey] = 'fogged';
          }
          byProvince[provinceId] = tiles;
        }

        expect(partialProvinceCount, greaterThanOrEqualTo(20));
        expect(
          visibility.values.where((v) => v != 'unknown').length,
          greaterThanOrEqualTo(100),
        );

        final startProvince = '$ow|partial0';
        final startTile = '$ow|partial0|0|0';
        final explorer = Unit(
          id: explorerId,
          type: kUnitTypeExplorer,
          ownerId: playerId,
          locationProvinceId: startProvince,
          tileKey: startTile,
          status: UnitStatus.idle,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: provinces, units: [explorer]),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {ow: byProvince},
          playerVisibilityByTile: {playerId: visibility},
        );
        final game = Game(
          id: 'g-scale',
          worldState: world,
          players: [player],
          minorNations: const [],
          tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
        );
        const topology = MapTopology(nodes: [], edges: []);

        final pending = WorkOrder(
          unitId: explorerId,
          target: kWorkTargetExplore,
          targetTileKey: startTile,
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            playerId: [pending],
          },
        );
        final view = buildPlayerView(game, topology, playerId);

        getAvailableWorkTargetsForUnit(
          view: view,
          game: game,
          topology: topology,
          currentOrders: orders,
          unitId: explorerId,
        );
        expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);

        getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: explorerId,
          workTarget: kWorkTargetExplore,
          currentOrders: orders,
        );
        expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);

        getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: explorerId,
          workTarget: kWorkTargetProspect,
          currentOrders: orders,
        );
        expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
      },
    );

    test(
      'multi-target availability matches shared-validator tile keys per target',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tileA = 'oldWorld|p1|0|0';
        const tileB = 'oldWorld|p1|1|0';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: true,
          stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
        );
        final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
        final builder = Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
          tileKey: tileA,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [builder]),
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
        final unitsById = {for (final u in view.ownUnits) u.id: u};
        final shared = buildIncrementalCandidateValidator(
          game: game,
          topology: topology,
          playerId: playerId,
          baseOrders: orders,
          resolution: orderResolutionContextFromView(view, game, unitsById: unitsById),
          factionMembership: DiplomacyFactionMembership.from(game),
        );

        final availability = getAvailableWorkTargetsForUnit(
          view: view,
          game: game,
          topology: topology,
          currentOrders: orders,
          unitId: 'b1',
        );

        expect(availability.assignable, isTrue);
        for (final target in availability.availableWorkTargetIdsSorted()) {
          expect(
            availability.validTileKeysByTarget[target],
            equals(
              getValidWorkOrderTileKeysWithVisibility(
                game: game,
                topology: topology,
                view: view,
                unitId: 'b1',
                workTarget: target,
                currentOrders: orders,
                sharedCandidateValidator: shared,
                playerOwnedProvinceIds: ownedIds,
              ),
            ),
          );
        }
      },
    );
  });
}
