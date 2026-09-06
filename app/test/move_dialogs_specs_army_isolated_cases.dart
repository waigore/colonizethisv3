// Isolated-army fixtures for move_dialogs_specs_army tests (Refs #4734 Slice E, #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kMoveArmySpecsIsolatedPlayerId = 'gp_isolated';
const kMoveArmySpecsIsolatedFrom = 'oldWorld|p_isolated';

const kIsolatedMoveArmySpecsTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: kMoveArmySpecsIsolatedFrom,
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

Game buildMoveArmySpecsIsolatedGame() {
  return Game(
    id: 'g_isolated_army',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: kMoveArmySpecsIsolatedFrom,
            regionId: 'oldWorld',
            ownerId: kMoveArmySpecsIsolatedPlayerId,
            displayName: 'Lonely',
          ),
        ],
        units: [
          Unit(
            id: 'u_isolated',
            type: 'musketeers',
            ownerId: kMoveArmySpecsIsolatedPlayerId,
            locationProvinceId: kMoveArmySpecsIsolatedFrom,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'aisolated',
          ownerId: kMoveArmySpecsIsolatedPlayerId,
          regionId: 'oldWorld',
          stationedProvinceId: kMoveArmySpecsIsolatedFrom,
          regimentUnitIds: ['u_isolated'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kMoveArmySpecsIsolatedFrom: ['oldWorld|p_isolated|0|0'],
        },
      },
    ),
    players: const [
      Player(
        id: kMoveArmySpecsIsolatedPlayerId,
        displayName: 'Isolated',
        isHuman: true,
        capitalProvinceId: kMoveArmySpecsIsolatedFrom,
      ),
    ],
  );
}
