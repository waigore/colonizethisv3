// Table-driven army-move heuristics suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_army_move_heuristics_fixtures.dart';

void osamhRunKeepsAtMostOneArmyMovePerArmyId() {
  final orders = armyMoveHeuristicsOrders();
  final list = orders.armyMoveOrdersByPlayerId[armyMoveHeuristicsGp] ?? [];
  final perArmy = <String, int>{};
  for (final o in list) {
    perArmy[o.armyId] = (perArmy[o.armyId] ?? 0) + 1;
  }
  expect(perArmy.values.every((c) => c <= 1), isTrue);
}

List<RunnableScenario> orderSuggestionArmyMoveHeuristicsScenarios() => const [
  rs('keeps at most one army move per army id', osamhRunKeepsAtMostOneArmyMovePerArmyId),
];
