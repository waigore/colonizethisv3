// Move army/fleet 320 dp dialog fixtures (Refs #4606 Slice D).
// SPEC/ui/mobile-adaptation.md § 7; move-army-dialog.md; move-fleet-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const moveDialogs320HumanPlayerId = 'gp_move_320_human';
const moveDialogs320RivalPlayerId = 'gp_move_320_rival';
const moveDialogs320OwnedFrom = 'oldWorld|p_320_from';
const moveDialogs320OwnedDest = 'oldWorld|p_320_owned_dest';
const moveDialogs320InvasionDest = 'oldWorld|p_320_invasion_dest';
const moveDialogs320OriginSea = 'sea_320_origin';
const moveDialogs320AdjacentSea = 'sea_320_adjacent';
const moveDialogs320CapitalProvince = 'oldWorld|p_320_capital';

MapTopology moveDialogs320ArmyTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: moveDialogs320OwnedFrom,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: moveDialogs320OwnedDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: moveDialogs320InvasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: moveDialogs320OwnedFrom, id2: moveDialogs320OwnedDest),
      TopologyEdge(
        id1: moveDialogs320OwnedFrom,
        id2: moveDialogs320InvasionDest,
      ),
    ],
  );
}

Game moveDialogs320ArmyGame() {
  return Game(
    id: 'g_move_army_320',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: moveDialogs320OwnedFrom,
            regionId: 'oldWorld',
            ownerId: moveDialogs320HumanPlayerId,
            displayName: 'Origin',
          ),
          Province(
            id: moveDialogs320OwnedDest,
            regionId: 'oldWorld',
            ownerId: moveDialogs320HumanPlayerId,
            displayName: 'Owned Dest',
          ),
          Province(
            id: moveDialogs320InvasionDest,
            regionId: 'oldWorld',
            ownerId: moveDialogs320RivalPlayerId,
            displayName: 'Invade Dest',
          ),
        ],
        units: [
          Unit(
            id: 'u_move_320',
            type: 'musketeers',
            ownerId: moveDialogs320HumanPlayerId,
            locationProvinceId: moveDialogs320OwnedFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_move_320',
          ownerId: moveDialogs320HumanPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: moveDialogs320OwnedFrom,
          regimentUnitIds: ['u_move_320'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          moveDialogs320OwnedFrom: ['oldWorld|p_320_from|0|0'],
          moveDialogs320OwnedDest: ['oldWorld|p_320_owned_dest|0|0'],
          moveDialogs320InvasionDest: ['oldWorld|p_320_invasion_dest|0|0'],
        },
      },
      playerVisibilityByTile: const {
        moveDialogs320HumanPlayerId: {
          'oldWorld|p_320_from|0|0': 'fullyVisible',
          'oldWorld|p_320_owned_dest|0|0': 'fullyVisible',
          'oldWorld|p_320_invasion_dest|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(
        id: moveDialogs320HumanPlayerId,
        displayName: 'Mobile Player',
        isHuman: true,
        capitalProvinceId: moveDialogs320OwnedFrom,
      ),
      Player(
        id: moveDialogs320RivalPlayerId,
        displayName: 'Mobile Rival',
        isHuman: false,
        capitalProvinceId: moveDialogs320InvasionDest,
      ),
    ],
  );
}

MapTopology moveDialogs320FleetTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: moveDialogs320OriginSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: moveDialogs320AdjacentSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(
        id1: moveDialogs320OriginSea,
        id2: moveDialogs320AdjacentSea,
      ),
    ],
  );
}

Game moveDialogs320FleetGame() {
  return Game(
    id: 'g_move_fleet_320',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: moveDialogs320CapitalProvince,
            regionId: 'oldWorld',
            ownerId: moveDialogs320HumanPlayerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
      portsByProvinceSeaboard: const {
        'oldWorld|p_320_capital|sea_320_origin': 'oldWorld|p_320_capital|0|0',
        'oldWorld|p_320_capital|sea_320_adjacent': 'oldWorld|p_320_capital|0|0',
      },
      seaZoneDisplayNameById: const {
        'oldWorld|sea_320_origin': 'Origin Sea',
        'oldWorld|sea_320_adjacent': 'Adjacent Sea',
      },
    ),
    players: const [
      Player(
        id: moveDialogs320HumanPlayerId,
        displayName: 'Mobile Admiral',
        isHuman: true,
        capitalProvinceId: moveDialogs320CapitalProvince,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: moveDialogs320CapitalProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

Fleet moveDialogs320Fleet() {
  return Fleet(
    id: 'f_move_320',
    ownerId: moveDialogs320HumanPlayerId,
    regionId: 'oldWorld',
    seaZoneId: moveDialogs320OriginSea,
    ships: const [ShipInstance(id: 'ship_move_320', typeId: 'carrack')],
  );
}

MoveArmyDialog buildMoveArmyDialog320() {
  final game = moveDialogs320ArmyGame();
  return MoveArmyDialog(
    army: game.worldState.armies.first,
    game: game,
    humanPlayerId: moveDialogs320HumanPlayerId,
    bus: AppEventBus.create(),
    topology: moveDialogs320ArmyTopology(),
    draftOrders: const Orders(),
  );
}

MoveFleetDialog buildMoveFleetDialog320() {
  return MoveFleetDialog(
    game: moveDialogs320FleetGame(),
    topology: moveDialogs320FleetTopology(),
    humanPlayerId: moveDialogs320HumanPlayerId,
    fleet: moveDialogs320Fleet(),
    bus: AppEventBus.create(),
  );
}
