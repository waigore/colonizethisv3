import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('suggestBuildOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        workerPool: const WorkerPool(peasants: 2),
        treasury: 500,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<BuildUnitOrder>>());
    });

    test('suggestBuildOrders returns ship when affordable', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final affordableShipTreasury =
          ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 2)
          .applyDelta(CommodityCatalog.fabric.id, 2);
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        workerPool: const WorkerPool(peasants: 1),
        treasury: affordableShipTreasury,
        stockpile: stockpile,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
          units: [],
        ),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final shipTypes = suggestions
          .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
          .toList();
      expect(
        shipTypes,
        isNotEmpty,
        reason:
            'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
      );
    });

    test(
      'suggestBuildOrders can return both regiment and ship when both affordable',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final affordableBothTreasury =
            ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 5)
            .applyDelta(CommodityCatalog.fabric.id, 5)
            .applyDelta(CommodityCatalog.castIron.id, 5);
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          capitalProvinceId: '$ow|p1',
          workerPool: const WorkerPool(peasants: 2, apprentices: 1),
          treasury: affordableBothTreasury,
          stockpile: stockpile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: playerId),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g1', worldState: world, players: [player]);
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestBuildOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final hasRegiment = suggestions.any(
          (o) => RegimentEconomyCatalog.byId.containsKey(o.unitType),
        );
        final hasShip = suggestions.any(
          (o) => ShipEconomyCatalog.byId.containsKey(o.unitType),
        );
        expect(
          hasRegiment,
          isTrue,
          reason: 'should suggest regiments when affordable',
        );
        expect(hasShip, isTrue, reason: 'should suggest ships when affordable');
      },
    );

    test('suggestResearchOrders returns list', () {
      const playerId = 'gp1';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(nodes: const [], edges: const []);
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<ResearchOrder>>());
    });

    test('suggestNavalMoveOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'fleet_gp1',
            ownerId: playerId,
            seaZoneId: 'sea1',
            regionId: ow,
            shipTypeIds: ['fluyte'],
          ),
        ],
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestNavalMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions, isA<List<NavalMoveOrder>>());
    });

    test('counter_spy work suggested for Spy in owned province with tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      const tileKey = 'oldWorld|p1|0|0';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeSpy,
        ownerId: playerId,
        locationProvinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': [tileKey],
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(suggestions.where((o) => o.target == kWorkTargetCounterSpy), isNotEmpty);
    });

    test(
      'purchase_land work suggested for Merchant when minor province has resource tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final ownProvince = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final minorProvince = Province(
          id: '$ow|minor1',
          regionId: ow,
          ownerId: 'minor1',
        );
        const tileKey = 'oldWorld|minor1|0|0';
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeMerchant,
          ownerId: playerId,
          locationProvinceId: '$ow|p1',
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [ownProvince, minorProvince],
            units: [unit],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              tileKey: 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|minor1': [tileKey],
            },
          },
          resourceByTileKey: {tileKey: 'grain'},
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'minor1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(game, topology, playerId);
        final suggestions = suggestWorkOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(
          suggestions.where((o) => o.target == kWorkTargetPurchaseLand),
          isNotEmpty,
        );
      },
    );
  });
}
