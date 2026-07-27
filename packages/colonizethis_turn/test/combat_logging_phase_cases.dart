// Shared fixtures for combat_logging_phase_test (Refs #4168 slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/turn_resolver_test_harness.dart';

List<Player> combatLoggingBattlePlayers() => [
  Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
  Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
];

List<Unit> combatLoggingBattleUnits() => [
  Unit(
    id: 'u1',
    type: 'grenadiers',
    ownerId: 'p1',
    locationProvinceId: turnTestOwProvinceId('P1'),
    medals: 2,
  ),
  Unit(
    id: 'u2',
    type: 'peasant_levies',
    ownerId: 'p2',
    locationProvinceId: turnTestOwProvinceId('P2'),
  ),
];

MapTopology combatLoggingTwoProvinceTopology() =>
    twoAdjacentOldWorldProvinceTopology();

Game combatLoggingTwoProvinceBattleGame({CombatMode? defaultCombatMode}) {
  return adjacentOwP1P2Game(
    units: combatLoggingBattleUnits(),
    players: combatLoggingBattlePlayers(),
    defaultCombatMode: defaultCombatMode,
    ensureMilitaryArmies: true,
  );
}

Orders combatLoggingAttackOrders() {
  return Orders(
    armyMoveOrdersByPlayerId: {
      'p1': [
        ArmyMoveOrder(
          armyId: fieldArmyIdFor('p1', turnTestOwProvinceId('P1')),
          destinationProvinceId: turnTestOwProvinceId('P2'),
        ),
      ],
    },
  );
}

Game combatLoggingSingleProvinceGame() {
  final base = turnTestOwSingleProvinceGame(
    units: [
      Unit(
        id: 'u1',
        type: 'grenadiers',
        ownerId: 'p1',
        locationProvinceId: turnTestOwProvinceId('P1'),
        medals: 2,
      ),
    ],
  );
  return base.copyWith(
    players: [base.players.first.copyWith(militaryLevel: 3)],
  );
}
