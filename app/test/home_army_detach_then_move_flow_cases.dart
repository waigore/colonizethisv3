// Fixtures for home army detach-then-move flow widget tests (Refs #4734 Slice E).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kHomeArmyDetachPlayerId = 'gp_detach';
const kHomeArmyDetachFrom = 'oldWorld|p_from';
const kHomeArmyDetachDest = 'oldWorld|p_dest';

MapTopology homeArmyDetachTopology() => const MapTopology(
      nodes: [
        TopologyNode(
          id: kHomeArmyDetachFrom,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: kHomeArmyDetachDest,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [TopologyEdge(id1: kHomeArmyDetachFrom, id2: kHomeArmyDetachDest)],
    );

Game buildHomeArmyDetachGame() {
  return Game(
    id: 'g_detach',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kHomeArmyDetachFrom,
            regionId: 'oldWorld',
            ownerId: kHomeArmyDetachPlayerId,
            displayName: 'From',
          ),
          Province(
            id: kHomeArmyDetachDest,
            regionId: 'oldWorld',
            ownerId: kHomeArmyDetachPlayerId,
            displayName: 'Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: kHomeArmyDetachPlayerId,
            locationProvinceId: kHomeArmyDetachFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'home',
          ownerId: kHomeArmyDetachPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kHomeArmyDetachFrom,
          regimentUnitIds: ['u1'],
          isHomeArmy: true,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kHomeArmyDetachFrom: ['oldWorld|p_from|0|0'],
          kHomeArmyDetachDest: ['oldWorld|p_dest|0|0'],
        },
      },
      playerVisibilityByTile: const {
        kHomeArmyDetachPlayerId: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_dest|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: kHomeArmyDetachPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kHomeArmyDetachFrom,
      ),
    ],
  );
}
