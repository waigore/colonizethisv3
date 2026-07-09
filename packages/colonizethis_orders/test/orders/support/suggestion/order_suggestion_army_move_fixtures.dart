// Shared army-move suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const armyMoveGp = 'gp1';
const armyMoveCap = 'oldWorld|cap';
const armyMoveP1 = 'oldWorld|p1';
const armyMoveP2 = 'oldWorld|p2';
const armyMoveNw = 'newWorld|col';

Game armyMoveGame0({String? extraNeighborProvinceId}) {
  final provinces = <Province>[
    Province(
      id: armyMoveCap,
      regionId: 'oldWorld',
      ownerId: armyMoveGp,
      townTileKey: 'oldWorld|cap|0|0',
    ),
    Province(id: armyMoveP1, regionId: 'oldWorld', ownerId: armyMoveGp),
  ];
  if (extraNeighborProvinceId != null) {
    provinces.add(
      Province(
        id: extraNeighborProvinceId,
        regionId: 'oldWorld',
        ownerId: armyMoveGp,
      ),
    );
  }
  return Game(
    id: 'g_army_sug',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: armyMoveGp,
            locationProvinceId: armyMoveP1,
            tileKey: 'oldWorld|p1|0|0',
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: armyMoveNw, regionId: 'newWorld', ownerId: armyMoveGp),
        ],
      ),
      armies: [
        Army(
          id: homeArmyIdFor(armyMoveGp),
          ownerId: armyMoveGp,
          regionId: 'oldWorld',
          stationedProvinceId: armyMoveCap,
          regimentUnitIds: const [],
          isHomeArmy: true,
        ),
        Army(
          id: 'field_a',
          ownerId: armyMoveGp,
          regionId: 'oldWorld',
          stationedProvinceId: armyMoveP1,
          regimentUnitIds: const ['u1'],
          isHomeArmy: false,
        ),
      ],
      playerVisibilityByTile: {
        armyMoveGp: {
          'oldWorld|cap|0|0': 'fullyVisible',
          'oldWorld|p1|0|0': 'fullyVisible',
          'newWorld|col|0|0': 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          armyMoveCap: ['oldWorld|cap|0|0'],
          armyMoveP1: ['oldWorld|p1|0|0'],
        },
        'newWorld': {
          armyMoveNw: ['newWorld|col|0|0'],
        },
      },
    ),
    players: [
      Player(
        id: armyMoveGp,
        displayName: 'T',
        isHuman: true,
        capitalProvinceId: armyMoveCap,
      ),
    ],
  );
}

MapTopology armyMoveTopology0({bool includeP2 = false}) {
  final nodes = <TopologyNode>[
    const TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    const TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    const TopologyNode(
      id: 'newWorld|col',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ];
  final edges = <TopologyEdge>[];
  if (includeP2) {
    nodes.add(
      const TopologyNode(
        id: 'oldWorld|p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    );
    edges.add(const TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2'));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

Game armyMoveGameWithPriorMoveToP2() {
  final game = armyMoveGame0(extraNeighborProvinceId: armyMoveP2);
  final topology = armyMoveTopology0(includeP2: true);
  final tileKeys = Map<String, List<String>>.from(
    game.worldState.tileKeysByRegionAndProvince['oldWorld']!,
  );
  tileKeys[armyMoveP2] = ['oldWorld|p2|0|0'];
  final ws = game.worldState.copyWith(
    tileKeysByRegionAndProvince: {
      ...game.worldState.tileKeysByRegionAndProvince,
      'oldWorld': tileKeys,
    },
    playerVisibilityByTile: {
      armyMoveGp: {
        ...game.worldState.playerVisibilityByTile[armyMoveGp]!,
        'oldWorld|p2|0|0': 'fullyVisible',
      },
    },
  );
  return game.copyWith(worldState: ws);
}

Army armyMoveFieldArmy(Game game) =>
    game.worldState.armies.firstWhere((a) => a.id == 'field_a');

Game armyMoveDestIdsGame() => Game(
      id: 'g_army_dest_ids',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: armyMoveCap,
              regionId: 'oldWorld',
              ownerId: armyMoveGp,
              townTileKey: 'oldWorld|cap|0|0',
            ),
            Province(id: armyMoveP1, regionId: 'oldWorld', ownerId: armyMoveGp),
            Province(id: armyMoveP2, regionId: 'oldWorld', ownerId: armyMoveGp),
          ],
          units: const [],
        ),
        newWorld: RegionData(
          provinces: [
            Province(id: armyMoveNw, regionId: 'newWorld', ownerId: armyMoveGp),
          ],
        ),
        armies: [
          Army(
            id: 'field_a',
            ownerId: armyMoveGp,
            regionId: 'oldWorld',
            stationedProvinceId: armyMoveP1,
            regimentUnitIds: const [],
            isHomeArmy: false,
          ),
        ],
        tileKeysByRegionAndProvince: const {},
      ),
      players: [
        Player(
          id: armyMoveGp,
          displayName: 'T',
          isHuman: true,
          capitalProvinceId: armyMoveCap,
        ),
      ],
    );

MapTopology armyMoveDestIdsTopology() => MapTopology(
      nodes: const [
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
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'newWorld|col',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
    );
