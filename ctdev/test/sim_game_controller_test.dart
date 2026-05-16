import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:ctdev/ctdev_log.dart';
import 'package:ctdev/sim_game_controller.dart';

void main() {
  group('SimGameController', () {
    setUpAll(initCtdevLogging);
    setUp(clearUiLog);

    test('stepFullTurn advances turn number', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
      );

      controller.stepFullTurn();

      expect(controller.game.worldState.turnState.turnNumber, 1);
      expect(getLastUiLogLines(), isNotEmpty);
    });

    test('stepFullTurn is a no-op when calendar campaign is halted', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g-halt',
        calendarCampaignHalted: true,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['P1'],
          ],
          resourceGrid: const [
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 1,
      );

      controller.stepFullTurn();

      expect(controller.game.worldState.turnState.turnNumber, 7);
      expect(controller.orderHistory, isEmpty);
    });

    test('fastForward stops early when military victory is set', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g-vic',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
        victory: const VictoryState(
          winnerPlayerId: 'p1',
          type: VictoryType.military,
          turnNumber: 3,
        ),
      );
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['P1'],
          ],
          resourceGrid: const [
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 1,
      );

      controller.fastForward(turns: 20);

      expect(controller.game.worldState.turnState.turnNumber, 3);
      expect(controller.orderHistory, isEmpty);
    });

    test('stepFullTurn records AI order history', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
      );

      controller.stepFullTurn();

      expect(
        controller.orderHistory,
        isNotEmpty,
        reason:
            'AI uses suggestion API; visibility must be set so moves are suggested',
      );
      for (final entry in controller.orderHistory) {
        expect(entry.turnNumber, 0);
        expect(entry.playerId, 'p1');
      }
    });

    test('order history records research and naval validation results', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'Power 1',
            isHuman: true,
            researchSlots: 2,
          ),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
          ],
        },
        researchOrdersByPlayerId: {
          'p1': [
            ResearchOrder(
              slotIndex: 0,
              techId: kTechIdPrintingPress,
              funding: ResearchFundingLevel.low,
            ),
          ],
        },
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(
              fleetId: 'no_such_fleet',
              destinationSeaZoneId: 'sz1',
            ),
          ],
        },
      );

      controller.advanceTurnForTesting(orders);

      final researchEntries = controller.orderHistory
          .where((e) => e.orderType == 'research')
          .toList();
      expect(researchEntries, hasLength(1));
      expect(researchEntries.single.summary, contains('Printing Press'));
      expect(researchEntries.single.status, OrderValidationStatus.accepted);

      final navalEntries = controller.orderHistory
          .where((e) => e.orderType == 'naval_move')
          .toList();
      expect(navalEntries, hasLength(1));
      expect(navalEntries.single.status, OrderValidationStatus.rejected);

      final moveEntries = controller.orderHistory
          .where((e) => e.orderType == 'move')
          .toList();
      expect(moveEntries, hasLength(1));
      expect(moveEntries.single.status, OrderValidationStatus.accepted);
    });

    test('turn trace export includes AI sections when enabled', () async {
      final traceRoot = await Directory.systemTemp.createTemp(
        'ct_turn_trace_ctdev_',
      );
      addTearDown(() async {
        if (await traceRoot.exists()) {
          await traceRoot.delete(recursive: true);
        }
      });
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );

      final game = Game(
        id: 'g_trace',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'p1'),
              Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: 'oldWorld|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'Power 1', isHuman: true),
        ],
      );

      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['P1'],
            ['P2'],
          ],
          resourceGrid: const [
            [Resource.grain],
            [Resource.grain],
          ],
        ),
        'newWorld': TileMapResult(
          width: 0,
          height: 0,
          grid: const [],
          resourceGrid: const [],
        ),
      };

      final controller = SimGameController(
        initialGame: game,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        baseSeed: 123,
        turnTraceEnabled: true,
        turnTraceRootDirectory: traceRoot.path,
      );
      controller.stepFullTurn();
      controller.stepFullTurn();

      await Future<void>.delayed(const Duration(milliseconds: 60));
      final traceDir = Directory('${traceRoot.path}/turn-traces/${game.id}');
      expect(await traceDir.exists(), isTrue);
      final files = traceDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      expect(files, hasLength(2), reason: 'ctdev disables trace pruning for long sessions');
      for (final f in files) {
        final payload =
            jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        expect(payload['schemaVersion'], 'v1');
      }
      final payload =
          jsonDecode(await files.last.readAsString()) as Map<String, dynamic>;
      final meta = payload['meta'] as Map<String, dynamic>;
      expect(meta['source'], 'ctdev');
      final ai = payload['ai'] as List<dynamic>;
      expect(ai, isNotEmpty);
      final firstAi = ai.first as Map<String, dynamic>;
      expect(firstAi['factionId'], 'p1');
      expect(firstAi['state'], isA<Map<String, dynamic>>());
      expect(firstAi['thresholds'], isA<Map<String, dynamic>>());
      expect(firstAi['outcome'], isA<Map<String, dynamic>>());
    });
  });
}
