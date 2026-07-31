// Fixtures for move army invasion intel widget goldens (Refs #4216).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

const moveArmyInvasionIntelGoldenPlayerId = 'gp_intel_golden';
const moveArmyInvasionIntelGoldenRivalId = 'gp_rival_golden';
const moveArmyInvasionIntelGoldenFrom = 'oldWorld|p_from';
const moveArmyInvasionIntelGoldenOwnedDest = 'oldWorld|p_owned';
const moveArmyInvasionIntelGoldenInvasionDest = 'oldWorld|p_invade';

const Size kMoveArmyInvasionIntelGoldenViewport = Size(360, 620);

MapTopology buildMoveArmyInvasionIntelGoldenTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: moveArmyInvasionIntelGoldenFrom,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: moveArmyInvasionIntelGoldenOwnedDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: moveArmyInvasionIntelGoldenInvasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(
        id1: moveArmyInvasionIntelGoldenFrom,
        id2: moveArmyInvasionIntelGoldenOwnedDest,
      ),
      TopologyEdge(
        id1: moveArmyInvasionIntelGoldenFrom,
        id2: moveArmyInvasionIntelGoldenInvasionDest,
      ),
    ],
  );
}

Game buildMoveArmyInvasionIntelGoldenGame({
  required Map<String, String> visibilityByTile,
  int fortLevel = 0,
  List<Unit> invasionUnits = const [],
  bool includeOwnedDestination = true,
}) {
  return Game(
    id: 'g_move_army_intel_golden',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: moveArmyInvasionIntelGoldenFrom,
            regionId: 'oldWorld',
            ownerId: moveArmyInvasionIntelGoldenPlayerId,
            displayName: 'Origin',
          ),
          if (includeOwnedDestination)
            Province(
              id: moveArmyInvasionIntelGoldenOwnedDest,
              regionId: 'oldWorld',
              ownerId: moveArmyInvasionIntelGoldenPlayerId,
              displayName: 'Owned Dest',
            ),
          Province(
            id: moveArmyInvasionIntelGoldenInvasionDest,
            regionId: 'oldWorld',
            ownerId: moveArmyInvasionIntelGoldenRivalId,
            displayName: 'Invade Dest',
            fortLevel: fortLevel,
          ),
        ],
        units: [
          Unit(
            id: 'u_mover',
            type: 'musketeers',
            ownerId: moveArmyInvasionIntelGoldenPlayerId,
            locationProvinceId: moveArmyInvasionIntelGoldenFrom,
          ),
          ...invasionUnits,
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'a_intel_golden',
          ownerId: moveArmyInvasionIntelGoldenPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: moveArmyInvasionIntelGoldenFrom,
          regimentUnitIds: ['u_mover'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          moveArmyInvasionIntelGoldenFrom: ['oldWorld|p_from|0|0'],
          if (includeOwnedDestination)
            moveArmyInvasionIntelGoldenOwnedDest: ['oldWorld|p_owned|0|0'],
          moveArmyInvasionIntelGoldenInvasionDest: ['oldWorld|p_invade|0|0'],
        },
      },
      playerVisibilityByTile: {moveArmyInvasionIntelGoldenPlayerId: visibilityByTile},
    ),
    players: const [
      Player(
        id: moveArmyInvasionIntelGoldenPlayerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: moveArmyInvasionIntelGoldenFrom,
      ),
      Player(
        id: moveArmyInvasionIntelGoldenRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: moveArmyInvasionIntelGoldenInvasionDest,
      ),
    ],
  );
}

Map<String, String> moveArmyInvasionIntelFullVisibilityTiles({
  bool includeOwnedDestination = true,
}) {
  return {
    'oldWorld|p_from|0|0': 'fullyVisible',
    if (includeOwnedDestination) 'oldWorld|p_owned|0|0': 'fullyVisible',
    'oldWorld|p_invade|0|0': 'fullyVisible',
  };
}
