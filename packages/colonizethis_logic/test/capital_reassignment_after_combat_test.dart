import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_world/src/world/capital_and_gp_fall.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyCapitalReassignmentAfterCombat', () {
    const ow = 'oldWorld';

    test('sets capital from chosen province townTileKey; no port/tileState change', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'sea1'),
          TopologyEdge(id1: 'P2', id2: 'P1'),
        ],
      );

      final portsBefore = const {'$ow|P1|sea1': '$ow|P1|0|0'};
      final tileStateBefore = TileMapState().setRoadLevel('$ow|P2|2|2', 2);

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: '$ow|P1',
                regionId: ow,
                ownerId: 'enemy',
                townTileKey: '$ow|P1|0|0',
              ),
              Province(
                id: '$ow|P2',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: '$ow|P2|2|2',
              ),
            ],
          ),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: portsBefore,
          tileState: tileStateBefore,
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            capitalTile: const CapitalTile(
              regionId: ow,
              provinceId: '$ow|P1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      final next = applyCapitalReassignmentAfterCombat(game, topology);

      final pl = next.players.single;
      expect(pl.capitalProvinceId, '$ow|P2');
      expect(pl.capitalTile!.toTileKey(), '$ow|P2|2|2');
      expect(next.worldState.portsByProvinceSeaboard, portsBefore);
      expect(next.worldState.tileState, tileStateBefore);
      final p2 = next.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|P2')
          .single;
      expect(p2.townTileKey, '$ow|P2|2|2');
    });

    test('prefers seaboard province by sorted id among owned', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P3',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'sea1'),
          TopologyEdge(id1: 'P2', id2: 'sea1'),
          TopologyEdge(id1: 'P3', id2: 'P2'),
        ],
      );

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: '$ow|P1',
                regionId: ow,
                ownerId: 'enemy',
                townTileKey: '$ow|P1|0|0',
              ),
              const Province(
                id: '$ow|P2',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: '$ow|P2|1|1',
              ),
              const Province(
                id: '$ow|P3',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: '$ow|P3|2|2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            capitalTile: const CapitalTile(
              regionId: ow,
              provinceId: '$ow|P1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      // P2 seaboard, P3 inland only; sorted seaboard ids → P2 before any inland-only.
      final next = applyCapitalReassignmentAfterCombat(game, topology);
      expect(next.players.single.capitalProvinceId, '$ow|P2');
      expect(next.players.single.capitalTile!.toTileKey(), '$ow|P2|1|1');
    });

    test('throws CapitalReassignmentFatalError when townTileKey missing', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: '$ow|P1',
                regionId: ow,
                ownerId: 'enemy',
                townTileKey: '$ow|P1|0|0',
              ),
              const Province(
                id: '$ow|P2',
                regionId: ow,
                ownerId: 'pl1',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'pl1',
            displayName: 'GP',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            capitalTile: const CapitalTile(
              regionId: ow,
              provinceId: '$ow|P1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      expect(
        () => applyCapitalReassignmentAfterCombat(game, topology),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });
}
