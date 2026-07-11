// ArmyMoveValidator armiesById equivalence fixtures (Refs #2394, #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../common/game_graphs.dart';
import 'move_validator_test_support.dart';

const amvArmiesByIdOw = 'oldWorld';

MapTopology amvArmiesByIdTwoProvinceTopology() =>
    moveValidatorTestTwoProvinceTopology(amvArmiesByIdOw);

const amvArmiesByIdValidator = ArmyMoveValidator();

Game amvArmiesByIdSampleGame() {
  const p1 = 'p1';
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: 0,
    players: const [Player(id: p1, displayName: 'P1', isHuman: true)],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$amvArmiesByIdOw|P1',
          regionId: amvArmiesByIdOw,
          ownerId: p1,
        ),
        Province(
          id: '$amvArmiesByIdOw|P2',
          regionId: amvArmiesByIdOw,
          ownerId: p1,
        ),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: p1,
          locationProvinceId: '$amvArmiesByIdOw|P1',
        ),
      ],
    ),
    armies: [moveValidatorTestFieldArmy(amvArmiesByIdOw, p1, 'P1', 'u1')],
    playerVisibilityByTile: const {
      p1: {
        'oldWorld|P1|0|0': 'fullyVisible',
        'oldWorld|P2|0|0': 'fullyVisible',
      },
    },
  );
}

Game amvArmiesByIdTwoGpPeaceGame() => ordersTwoProvinceOwnedGame(
  id: 'g2',
  turnNumber: 0,
  p1Local: 'P1',
  p2Local: 'P2',
  owner1: 'p1',
  owner2: 'p2',
  players: const [
    Player(id: 'p1', displayName: 'P1', isHuman: true),
    Player(id: 'p2', displayName: 'P2', isHuman: false),
  ],
  units: [
    Unit(
      id: 'u1',
      type: 'pikemen',
      ownerId: 'p1',
      locationProvinceId: '$amvArmiesByIdOw|P1',
    ),
  ],
  armies: [moveValidatorTestFieldArmy(amvArmiesByIdOw, 'p1', 'P1', 'u1')],
  playerVisibilityByTile: const {
    'p1': {
      'oldWorld|P1|0|0': 'fullyVisible',
      'oldWorld|P2|0|0': 'fullyVisible',
    },
  },
);

Map<String, Army> amvArmiesByIdFromGame(Game game) => {
  for (final a in game.worldState.armies) a.id: a,
};
