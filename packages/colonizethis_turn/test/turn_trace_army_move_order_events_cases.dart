// Shared fixtures for turn_trace_army_move_order_events_test (Refs #4342 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/turn_resolver_test_harness.dart';

const armyMoveTraceOw = turnTestOldWorldRegionId;
const armyMoveTraceP1 = '$armyMoveTraceOw|a';
const armyMoveTraceP2 = '$armyMoveTraceOw|b';

MapTopology armyMoveTraceTwoProvinceTopology({bool adjacent = true}) =>
    twoAdjacentOldWorldProvinceTopology(
      id1: armyMoveTraceP1,
      id2: armyMoveTraceP2,
      adjacent: adjacent,
    );

Game armyMoveTraceGameWithSingleArmy({
  String playerId = 'gp1',
  String armyId = 'afield',
  String stationedProvinceId = armyMoveTraceP1,
  String otherProvinceId = armyMoveTraceP2,
  bool isHomeArmy = false,
}) =>
    Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: stationedProvinceId,
              regionId: armyMoveTraceOw,
              ownerId: playerId,
            ),
            Province(
              id: otherProvinceId,
              regionId: armyMoveTraceOw,
              ownerId: playerId,
            ),
          ],
          units: [
            Unit(
              id: 'r1',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: stationedProvinceId,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: armyId,
            ownerId: playerId,
            regionId: armyMoveTraceOw,
            stationedProvinceId: stationedProvinceId,
            regimentUnitIds: const ['r1'],
            isHomeArmy: isHomeArmy,
          ),
        ],
      ),
      players: [
        Player(
          id: playerId,
          displayName: 'P',
          isHuman: true,
          capitalProvinceId: stationedProvinceId,
        ),
      ],
    );

Game armyMoveTraceGhostArmyGame() => Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(id: armyMoveTraceP1, regionId: armyMoveTraceOw, ownerId: 'gp1'),
            Province(id: armyMoveTraceP2, regionId: armyMoveTraceOw, ownerId: 'gp1'),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [Player(id: 'gp1', displayName: 'P', isHuman: true)],
    );

Game armyMoveTraceInvalidAdjacencyGame() => Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(id: armyMoveTraceP1, regionId: armyMoveTraceOw, ownerId: 'gp1'),
            Province(id: armyMoveTraceP2, regionId: armyMoveTraceOw, ownerId: 'gp2'),
          ],
          units: [
            Unit(
              id: 'r1',
              type: 'musketeers',
              ownerId: 'gp1',
              locationProvinceId: armyMoveTraceP1,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: 'afield',
            ownerId: 'gp1',
            regionId: armyMoveTraceOw,
            stationedProvinceId: armyMoveTraceP1,
            regimentUnitIds: const ['r1'],
            isHomeArmy: false,
          ),
        ],
      ),
      players: const [
        Player(id: 'gp1', displayName: 'P1', isHuman: true),
        Player(id: 'gp2', displayName: 'P2', isHuman: false),
      ],
    );
