// Pre-combat index scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/src/combat/pre_combat_index.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'pre_combat_index_test_support.dart';
import 'scenario_runner.dart';

const _ow = preCombatIndexOldWorldRegionId;

List<RunnableScenario> preCombatMovementIndexBuildScenarios() => [
  RunnableScenario(
    scenarioId: 'pci-build-players-armies',
    label: 'greatPowerIds contains every player id and armiesById every army',
    run: () {
      final game = preCombatIndexFixtureGame(
        armies: [
          preCombatIndexArmy('a1', ownerId: 'p1'),
          preCombatIndexArmy('a2', ownerId: 'p2'),
        ],
      );
      final index = PreCombatMovementIndex.build(game, const Orders());
      expect(index.greatPowerIds, {'p1', 'p2'});
      expect(index.armiesById.keys.toSet(), {'a1', 'a2'});
      expect(index.armiesById['a1']!.ownerId, 'p1');
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-build-move-order',
    label:
        'includes Great Power army moves with destinations resolved in order',
    run: () {
      final game = preCombatIndexFixtureGame(
        armies: [
          preCombatIndexArmy(
            'a1',
            ownerId: 'p1',
            stationedProvinceId: '$_ow|p1',
          ),
          preCombatIndexArmy(
            'a2',
            ownerId: 'p1',
            stationedProvinceId: '$_ow|p5',
          ),
        ],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2'),
            ArmyMoveOrder(armyId: 'a2', destinationProvinceId: 'p6'),
          ],
        },
      );
      final index = PreCombatMovementIndex.build(game, orders);
      expect(
        index.greatPowerArmyMoves
            .map(
              (m) => '${m.factionId}:${m.army.id}:${m.destinationProvinceId}',
            )
            .toList(),
        ['p1:a1:$_ow|p2', 'p1:a2:$_ow|p6'],
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-build-skip-non-gp',
    label: 'skips moves from factions that are not Great Powers',
    run: () {
      final game = preCombatIndexFixtureGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        armies: [preCombatIndexArmy('a1', ownerId: 'minor1')],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'minor1': [
            ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2'),
          ],
        },
      );
      expect(
        PreCombatMovementIndex.build(game, orders).greatPowerArmyMoves,
        isEmpty,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-build-skip-home',
    label: 'skips home armies',
    run: () {
      final game = preCombatIndexFixtureGame(
        armies: [preCombatIndexArmy('a1', ownerId: 'p1', isHomeArmy: true)],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2')],
        },
      );
      expect(
        PreCombatMovementIndex.build(game, orders).greatPowerArmyMoves,
        isEmpty,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-build-skip-unknown',
    label: 'skips orders for unknown army ids',
    run: () {
      final game = preCombatIndexFixtureGame(
        armies: [preCombatIndexArmy('a1', ownerId: 'p1')],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [
            ArmyMoveOrder(armyId: 'ghost', destinationProvinceId: '$_ow|p2'),
          ],
        },
      );
      expect(
        PreCombatMovementIndex.build(game, orders).greatPowerArmyMoves,
        isEmpty,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'pci-build-skip-owner-mismatch',
    label: 'skips orders whose army owner differs from the ordering faction',
    run: () {
      final game = preCombatIndexFixtureGame(
        armies: [preCombatIndexArmy('a1', ownerId: 'p2')],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: const {
          'p1': [ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$_ow|p2')],
        },
      );
      expect(
        PreCombatMovementIndex.build(game, orders).greatPowerArmyMoves,
        isEmpty,
      );
    },
  ),
];
