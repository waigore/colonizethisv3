import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/army_movement.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/world_test_support.dart';

/// Army move application pins (Refs #3290 / densify #4330 Slice C).
/// SPEC/game/military-armies.md and SPEC/program/movement.md.

void registerArmyMovementApplyCases() {
  group('applyCrossRegionArmyMovesWithinOwnedProvinces', () {
    test('moves army instantly to an owned province in another region', () {
      final world = armyMoveWorld(
        armies: [testArmy('a1')],
        newWorld: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p1'),
        ],
      );
      final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
        game: TestFixtures.singlePlayerGame(
          const Player(id: 'p1', displayName: 'P1', isHuman: true),
          gameId: 'g',
          worldState: world,
        ),
        worldState: world,
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'newWorld|n1'),
          ],
        },
      );
      expect(
        result.worldState.armies.single.stationedProvinceId,
        'newWorld|n1',
      );
      expect(result.worldState.armies.single.regionId, 'newWorld');
      expect(result.remainingArmyMoveOrdersByPlayerId, isEmpty);
    });

    test('leaves same-region or unowned-destination orders as remaining', () {
      final world = armyMoveWorld(
        armies: [testArmy('a1'), testArmy('home', isHomeArmy: true)],
        oldWorld: const [
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'p1'),
        ],
        newWorld: const [
          Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'p2'),
        ],
      );
      final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
        game: TestFixtures.singlePlayerGame(
          const Player(id: 'p1', displayName: 'P1', isHuman: true),
          gameId: 'g',
          worldState: world,
        ),
        worldState: world,
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'oldWorld|p2'),
            ArmyMoveOrder(armyId: 'home', destinationProvinceId: 'newWorld|n1'),
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'newWorld|n1'),
          ],
        },
      );
      expect(result.remainingArmyMoveOrdersByPlayerId['p1'], hasLength(3));
      expect(result.worldState.armies, world.armies);
    });

    test(
      'cross-region army moves reuse updated army location between orders',
      () {
        const playerId = 'p1';
        const oldProvince = 'oldWorld|p1';
        const newProvince = 'newWorld|n1';
        final world = armyMoveWorld(
          armies: [
            testArmy(
              'field',
              stationedProvinceId: oldProvince,
              regimentUnitIds: const ['r1'],
            ),
          ],
          oldWorld: const [
            Province(id: oldProvince, regionId: 'oldWorld', ownerId: playerId),
          ],
          oldWorldUnits: [
            Unit(
              id: 'r1',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: oldProvince,
            ),
          ],
          newWorld: const [
            Province(id: newProvince, regionId: 'newWorld', ownerId: playerId),
          ],
        );
        final result = applyCrossRegionArmyMovesWithinOwnedProvinces(
          game: TestFixtures.singlePlayerGame(
            const Player(id: playerId, displayName: 'P1', isHuman: true),
            gameId: 'g-seq',
            worldState: world,
          ),
          worldState: world,
          armyMoveOrdersByPlayerId: const {
            playerId: [
              ArmyMoveOrder(
                armyId: 'field',
                destinationProvinceId: newProvince,
              ),
              ArmyMoveOrder(
                armyId: 'field',
                destinationProvinceId: oldProvince,
              ),
            ],
          },
        );
        expect(result.remainingArmyMoveOrdersByPlayerId, isEmpty);
        expect(
          result.worldState.armies.single.stationedProvinceId,
          oldProvince,
        );
        expect(
          result.worldState.oldWorld.units.single.locationProvinceId,
          oldProvince,
        );
      },
    );
  });
}
