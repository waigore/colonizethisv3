// ArmyMoveValidator armiesById equivalence fixtures (Refs #2394, #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'move_validator_test_support.dart';

const amvArmiesByIdOw = 'oldWorld';

MapTopology amvArmiesByIdTwoProvinceTopology() =>
    moveValidatorTestTwoProvinceTopology(amvArmiesByIdOw);

const amvArmiesByIdValidator = ArmyMoveValidator();

Game amvArmiesByIdSampleGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$amvArmiesByIdOw|P1', regionId: amvArmiesByIdOw, ownerId: 'p1'),
          Province(id: '$amvArmiesByIdOw|P2', regionId: amvArmiesByIdOw, ownerId: 'p1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$amvArmiesByIdOw|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        moveValidatorTestFieldArmy(amvArmiesByIdOw, 'p1', 'P1', 'u1'),
      ],
      playerVisibilityByTile: const {
        'p1': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}

Game amvArmiesByIdTwoGpPeaceGame() {
  return Game(
    id: 'g2',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$amvArmiesByIdOw|P1', regionId: amvArmiesByIdOw, ownerId: 'p1'),
          Province(id: '$amvArmiesByIdOw|P2', regionId: amvArmiesByIdOw, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$amvArmiesByIdOw|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        moveValidatorTestFieldArmy(amvArmiesByIdOw, 'p1', 'P1', 'u1'),
      ],
      playerVisibilityByTile: const {
        'p1': {
          'oldWorld|P1|0|0': 'fullyVisible',
          'oldWorld|P2|0|0': 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ],
  );
}

Map<String, Army> amvArmiesByIdFromGame(Game game) => {
      for (final a in game.worldState.armies) a.id: a,
    };
