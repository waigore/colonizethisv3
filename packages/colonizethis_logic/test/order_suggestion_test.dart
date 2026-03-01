import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Order suggestion', () {
    test('suggestMoveOrders only returns moves that pass validation', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );

      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow);

      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [p1, p2],
          units: [unit],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p1|0|0': 'fullyVisible',
            'oldWorld|p2|0|0': 'fogged',
          },
        },
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );

      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(view, game, topology, const Orders());

      expect(suggestions.length, 1);
      expect(suggestions.first.unitId, 'u1');
      expect(suggestions.first.destinationProvinceId, 'oldWorld|p2');
    });

    test('suggestMoveOrders throws when source province has unknown visibility', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      // No visibility for p1: source province unknown → game raises.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final view = buildPlayerView(game, topology, playerId);
      expect(
        () => suggestMoveOrders(view, game, topology, const Orders()),
        throwsStateError,
      );
    });

    test('move suggestions use unit locationProvinceId (tileKey-derived for civilians)', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(
        id: playerId,
        displayName: 'Test GP',
        isHuman: false,
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
      final p3 = Province(id: '$ow|p3', regionId: ow, ownerId: playerId);
      // Civilian in p2 by tileKey; provinceId can differ (e.g. legacy). Source = locationProvinceId = p2.
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
        tileKey: 'oldWorld|p2|0|0',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [p1, p2, p3],
          units: [unit],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p2|0|0': 'fullyVisible',
            'oldWorld|p3|0|0': 'fogged',
          },
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      // p2 adjacent to p3 only (so suggested moves are from p2 → p3, not from p1).
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p2', id2: 'p3'),
        ],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestMoveOrders(view, game, topology, const Orders());
      expect(suggestions.length, 1);
      expect(suggestions.first.unitId, 'u1');
      expect(suggestions.first.destinationProvinceId, 'oldWorld|p3');
      // Move is from p2 (unit's location province), not p1. Unit with tileKey uses compound id.
      expect(view.ownUnitsById['u1']!.locationProvinceId, 'oldWorld|p2');
    });

    test('no explore suggestion when province unknown', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      // No visibility: p1 unknown, so explore not suggested.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      expect(
        suggestions.where((o) => o.target == 'explore'),
        isEmpty,
      );
    });

    test('no prospect suggestion when province not at least fogged', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: 'tribe1');
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      // p1 only revealed (not fogged) — prospect requires fogged or better.
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'revealed'},
        },
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      expect(
        suggestions.where((o) => o.target == 'prospect'),
        isEmpty,
      );
    });

    test('prospect suggestion when province fogged and tiles in province', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Explorer',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      const tileKey = 'oldWorld|p1|0|0';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {tileKey: 'fogged'},
        },
        tileKeysByRegionAndProvince: {
          ow: {'$ow|p1': [tileKey]},
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      expect(
        suggestions.where((o) => o.target == 'prospect'),
        isNotEmpty,
      );
      expect(suggestions.firstWhere((o) => o.target == 'prospect').targetTileKey, tileKey);
    });

    test('work suggestions only for unit current province', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
      );
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {'$ow|p1': ['oldWorld|p1|0|0']},
        },
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      // All suggested work orders are for u1, which is in p1; no order targets another province.
      for (final o in suggestions) {
        expect(o.unitId, 'u1');
        final u = view.ownUnitsById[o.unitId];
        expect(u, isNotNull);
        expect(u!.provinceId, 'oldWorld|p1');
      }
    });

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
        nodes: const [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(view, game, topology, const Orders());
      expect(suggestions, isA<List<BuildUnitOrder>>());
    });

    test('suggestBuildOrders returns ship when affordable', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final stockpile = const Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 2)
          .applyDelta(CommodityCatalog.fabric.id, 2);
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: '$ow|p1',
        treasury: 100,
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
        nodes: const [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(view, game, topology, const Orders());
      final shipTypes = suggestions.where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).toList();
      expect(shipTypes, isNotEmpty, reason: 'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack');
    });

    test('suggestBuildOrders can return both regiment and ship when both affordable', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
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
        treasury: 500,
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
        nodes: const [TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province)],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestBuildOrders(view, game, topology, const Orders());
      final hasRegiment = suggestions.any((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType));
      final hasShip = suggestions.any((o) => ShipEconomyCatalog.byId.containsKey(o.unitType));
      expect(hasRegiment, isTrue, reason: 'should suggest regiments when affordable');
      expect(hasShip, isTrue, reason: 'should suggest ships when affordable');
    });

    test('suggestResearchOrders returns list', () {
      const playerId = 'gp1';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false, treasury: 1000);
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(nodes: const [], edges: const []);
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestResearchOrders(view, game, topology, const Orders());
      expect(suggestions, isA<List<ResearchOrder>>());
    });

    test('suggestNavalMoveOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(id: 'fleet_gp1', ownerId: playerId, seaZoneId: 'sea1', regionId: ow, shipTypeIds: ['fluyte']),
        ],
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: ow, type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestNavalMoveOrders(view, game, topology, const Orders());
      expect(suggestions, isA<List<NavalMoveOrder>>());
    });

    test('counter_spy work suggested for Spy in owned province with tiles', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      const tileKey = 'oldWorld|p1|0|0';
      final unit = Unit(
        id: 'u1',
        type: 'Spy',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1], units: [unit]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {playerId: {tileKey: 'fullyVisible'}},
        tileKeysByRegionAndProvince: {ow: {'$ow|p1': [tileKey]}},
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      expect(
        suggestions.where((o) => o.target == 'counter_spy'),
        isNotEmpty,
      );
    });

    test('purchase_land work suggested for Merchant when minor province has resource tile', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 500,
      );
      final ownProvince = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
      final minorProvince = Province(id: '$ow|minor1', regionId: ow, ownerId: 'minor1');
      const tileKey = 'oldWorld|minor1|0|0';
      final unit = Unit(
        id: 'u1',
        type: 'Merchant',
        ownerId: playerId,
        provinceId: '$ow|p1',
      );
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [ownProvince, minorProvince],
          units: [unit],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          playerId: {'oldWorld|p1|0|0': 'fullyVisible', tileKey: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {'$ow|p1': ['oldWorld|p1|0|0'], '$ow|minor1': [tileKey]},
        },
        resourceByTileKey: {tileKey: 'grain'},
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        overtureStates: const [
          OvertureState(gpId: 'gp1', targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'minor1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestWorkOrders(view, game, topology, const Orders());
      expect(
        suggestions.where((o) => o.target == 'purchase_land'),
        isNotEmpty,
      );
    });

    test('suggestNavalMissionOrders returns list', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: [
          Fleet(id: 'fleet_gp1', ownerId: playerId, seaZoneId: 'sea1', regionId: ow, shipTypeIds: ['fluyte']),
        ],
      );
      final game = Game(id: 'g1', worldState: world, players: [player]);
      final topology = MapTopology(
        nodes: const [TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone)],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, playerId);
      final suggestions = suggestNavalMissionOrders(view, game, topology, const Orders());
      expect(suggestions, isA<List<NavalMissionOrder>>());
    });
  });

  group('filterMoveOrdersByDiplomacy and getProvinceOwnerMap', () {
    test('getProvinceOwnerMap returns owner by full province id', () {
      const ow = 'oldWorld';
      final p1 = Province(id: 'p1', regionId: ow, ownerId: 'gp1');
      final p2 = Province(id: 'p2', regionId: ow, ownerId: 'gp2');
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: []),
        newWorld: const RegionData(),
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
      );
      final map = getProvinceOwnerMap(game);
      expect(map['oldWorld|p1'], 'gp1');
      expect(map['oldWorld|p2'], 'gp2');
    });

    test('filterMoveOrdersByDiplomacy drops move to at-peace faction', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 50, state: RelationState.atPeace),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|p2'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered, isEmpty, reason: 'move to gp2 at peace should be dropped');
    });

    test('filterMoveOrdersByDiplomacy keeps move to at-war faction', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 0, state: RelationState.atWar),
        ],
      );
      final orders = [
        MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|p2'),
      ];
      final filtered = filterMoveOrdersByDiplomacy(game, 'gp1', orders);
      expect(filtered.length, 1);
      expect(filtered.first.destinationProvinceId, 'oldWorld|p2');
    });
  });
}

