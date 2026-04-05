import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('isAiControlled', () {
    test('uses explicit aiControlByGpId when present', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        ],
        aiControlByGpId: const {'gp1': true},
      );

      expect(isAiControlled(game, 'gp1'), isTrue);
    });

    test('falls back to !isHuman when no explicit entry', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );

      expect(isAiControlled(game, 'gp1'), isFalse);
      expect(isAiControlled(game, 'gp2'), isTrue);
    });
  });

  group('generateOrdersForGame', () {
    MapTopology _simpleTopology() {
      return const MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );
    }

    Game _baseGame() {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
          Player(id: 'gp2', displayName: 'Human GP', isHuman: true),
        ],
        globalGameSeed: 123,
        aiSeedByGpId: const {'gp1': 999},
      );
    }

    test('does not attack factions at peace or Minors without war', () {
      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        globalGameSeed: 123,
        aiSeedByGpId: const {'gp1': 999},
      );

      final orders = generateOrdersForGame(game, _simpleTopology());
      final moves = orders.moveOrdersByPlayerId['gp1'] ?? const [];
      // AI should not emit attacks against Minor1 because there is no war relation.
      expect(
        moves.where((m) => m.destinationProvinceId == 'oldWorld|P2'),
        isEmpty,
      );
    });

    test('is deterministic for same game and seeds', () {
      final game = _baseGame();
      final topology = _simpleTopology();

      final o1 = generateOrdersForGame(game, topology);
      final o2 = generateOrdersForGame(game, topology);
      expect(o1, equals(o2));
    });

    test('generateOrdersForGame produces moves and research when legal targets exist', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'gp1'),
              // Unowned neighbor so movement is rules-legal and not blocked by diplomacy.
              Province(id: '$ow|P2', regionId: ow),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: '$ow|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              '$ow|P1|0|0': 'fullyVisible',
              '$ow|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI GP', isHuman: false),
        ],
        globalGameSeed: 123,
        aiSeedByGpId: const {'gp1': 999},
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final orders = generateOrdersForGame(game, topology);
      final armyMoves = orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      final research = orders.researchOrdersByPlayerId['gp1'] ?? const [];

      expect(armyMoves, isNotEmpty,
          reason: 'AI should army-move into unowned neighboring province');
      expect(research, isNotEmpty, reason: 'AI should also pick at least one research target');
    });

    test('generateOrdersForPlayer returns empty for human player', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: const [
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
          ]),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
        ],
      );
      final orders = generateOrdersForPlayer(game, _simpleTopology(), 'gp1');
      expect(orders, equals(const Orders()));
    });

    test('generateOrdersForPlayer emits build_rail when tile maps enable rail targets', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      TileMapResult railTileMap() => TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [TerrainType.plains],
        ],
      );

      Stockpile railStockpile() => Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 10)
          .applyDelta(CommodityCatalog.steel.id, 10);

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      final game = Game(
        id: 'g-rail-ai',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: provinceId, regionId: ow, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'rail1',
                type: 'Rail Builder',
                ownerId: 'gp1',
                locationProvinceId: provinceId,
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: TileMapState().setRoadLevel(tileKey, 1),
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [tileKey],
            },
          },
          playerVisibilityByTile: const {
            'gp1': {tileKey: 'fullyVisible'},
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'AI GP',
            isHuman: false,
            capitalProvinceId: provinceId,
            stockpile: railStockpile(),
            techUnlocked: const {'early_steam_engine': true},
          ),
        ],
        globalGameSeed: 42,
        aiSeedByGpId: const {'gp1': 7},
      );

      final orders = generateOrdersForPlayer(
        game,
        topology,
        'gp1',
        tileMapByRegion: {ow: railTileMap()},
      );
      final work = orders.workOrdersByPlayerId['gp1'] ?? const [];
      expect(
        work.any((w) => w.target == 'build_rail'),
        isTrue,
        reason: 'tile maps + road 1 + tech should allow build_rail in work suggestions',
      );
    });

    test('generateOrdersForGameFullAI aggregates orders including naval and diplo', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(id: 'u1', type: 'grenadiers', ownerId: 'gp1', locationProvinceId: 'oldWorld|P1'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );
      final result = generateOrdersForGameFullAI(game, topology);
      final orders = result.orders;
      expect(orders.moveOrdersByPlayerId, isNotNull);
      expect(orders.buildUnitOrdersByPlayerId, isNotNull);
      expect(orders.researchOrdersByPlayerId, isNotNull);
      expect(orders.navalMoveOrdersByPlayerId, isNotNull);
      expect(orders.navalMissionOrdersByPlayerId, isNotNull);
      expect(orders.diplomaticOrdersByPlayerId, isNotNull);
      expect(
        orders.researchOrdersByPlayerId['gp1'],
        isNotEmpty,
        reason: 'full AI should produce at least research when no capital',
      );
      expect(result.economyPlansByPlayerId.containsKey('gp1'), isTrue);
    });

    test('generateOrdersForGameFullAI preserves naval mission orders from per-player AI', () {
      // Regression for gap #1: naval mission orders must be aggregated, not dropped.
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(id: 'u1', type: 'grenadiers', ownerId: 'gp1', locationProvinceId: 'oldWorld|P1'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 1,
        aiSeedByGpId: const {'gp1': 1},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );
      final singleResult = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      final gameResult = generateOrdersForGameFullAI(game, topology);
      expect(
        gameResult.orders.navalMissionOrdersByPlayerId['gp1'],
        equals(singleResult.orders.navalMissionOrdersByPlayerId['gp1']),
        reason: 'full-AI aggregation must include naval mission orders (SPEC gap #1)',
      );
      expect(
        gameResult.orders.navalMoveOrdersByPlayerId['gp1'],
        equals(singleResult.orders.navalMoveOrdersByPlayerId['gp1']),
        reason: 'full-AI aggregation must include naval move orders',
      );
    });

    test('generateOrdersForPlayerFullAI can emit cross-region army move', () {
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const nw = 'newWorld|col';
      final game = Game(
        id: 'g_full_ai_army',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'gp1',
                locationProvinceId: p1,
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: nw, regionId: 'newWorld', ownerId: 'gp1'),
            ],
          ),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
            Army(
              id: 'field_a',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|cap|0|0': 'fullyVisible',
              'oldWorld|p1|0|0': 'fullyVisible',
              'newWorld|col|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: ['oldWorld|cap|0|0'],
              p1: ['oldWorld|p1|0|0'],
            },
            'newWorld': {
              nw: ['newWorld|col|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'AI',
            isHuman: false,
            leaderKey: 'victoria',
            capitalProvinceId: cap,
          ),
        ],
        globalGameSeed: 3,
        aiSeedByGpId: const {'gp1': 77},
        hiddenAgendaByGpId: const {'gp1': 'warmonger'},
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'oldWorld|cap',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'newWorld|col',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      final result = generateOrdersForPlayerFullAI(game, topology, 'gp1');
      final armyMoves =
          result.orders.armyMoveOrdersByPlayerId['gp1'] ?? const [];
      expect(
        armyMoves.any((m) => m.destinationProvinceId == nw),
        isTrue,
        reason: 'full AI should issue army move onto owned province in other region',
      );
    });
  });
}

