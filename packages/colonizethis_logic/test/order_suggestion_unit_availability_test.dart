import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('getAvailableWorkTargetsForUnit (Refs #2133)', () {
    test('short-circuits when unit has pending draft work (no accept probes)', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      const tile0 = '$ow|p1|0|0';
      const tile1 = '$ow|p1|1|0';

      final explorer = Unit(
        id: 'E1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: provinceId,
        tileKey: tile0,
        status: UnitStatus.idle,
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: playerId),
          ],
          units: [explorer],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          playerId: {
            tile0: 'fogged',
            tile1: 'fogged',
          },
        },
        tileKeysByRegionAndProvince: {
          ow: {
            provinceId: [tile0, tile1],
          },
        },
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
          TopologyNode(
            id: 'p1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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
              targetTileKey: tile0,
            ),
          ],
        },
      );

      OrderSuggestionAcceptProbe.reset();
      OrderSuggestionAcceptProbe.enabled = true;
      addTearDown(() {
        OrderSuggestionAcceptProbe.enabled = false;
        OrderSuggestionAcceptProbe.reset();
      });

      final availability = getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: orders,
        unitId: 'E1',
      );

      expect(availability.assignable, isFalse);
      expect(availability.blockedReason, 'pending_draft_work');
      expect(availability.enabledWorkTargetIds(), isEmpty);
      expect(OrderSuggestionAcceptProbe.count, 0);
    });
  });

  group('getValidWorkOrderTileKeysWithVisibility pending draft (Refs #2133)', () {
    test('returns empty without probing when pending targets another work type',
        () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      const provinceId = '$ow|p1';
      final tiles = List.generate(
        120,
        (i) => '$ow|p1|$i|0',
      );

      final explorer = Unit(
        id: 'E1',
        type: kUnitTypeExplorer,
        ownerId: playerId,
        locationProvinceId: provinceId,
        tileKey: tiles.first,
        status: UnitStatus.idle,
      );

      final vis = <String, String>{
        for (final t in tiles) t: 'fogged',
      };

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
        resourceByTileKey: {
          for (final t in tiles) t: 'coal',
        },
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
          TopologyNode(
            id: 'p1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
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

      OrderSuggestionAcceptProbe.reset();
      OrderSuggestionAcceptProbe.enabled = true;
      addTearDown(() {
        OrderSuggestionAcceptProbe.enabled = false;
        OrderSuggestionAcceptProbe.reset();
      });

      final validProspect = getValidWorkOrderTileKeysWithVisibility(
        game: game,
        topology: topology,
        view: view,
        unitId: 'E1',
        workTarget: kWorkTargetProspect,
        currentOrders: orders,
      );

      expect(validProspect, isEmpty);
      expect(OrderSuggestionAcceptProbe.count, 0);
    });
  });
}
