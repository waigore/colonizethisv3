// Table-driven order suggestion helper scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_helpers_expectations.dart';

/// One row in order suggestion helper scenario tables.
class OrderSuggestionHelpersScenario implements RefsScenario {
  const OrderSuggestionHelpersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionHelpersTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionHelpersScenario(OrderSuggestionHelpersScenario scenario) {
  runOrderSuggestionHelpersExpectation(scenario.target);
}

/// Scenarios for filterArmyMoveOrdersByDiplomacy.
List<OrderSuggestionHelpersScenario> filterArmyMoveOrdersByDiplomacyScenarios() =>
    const [
      OrderSuggestionHelpersScenario(
        label: 'drops move into minor-owned province when relation row is absent',
        target: OrderSuggestionHelpersTarget.dropsMoveWhenRelationAbsent,
        refs: '#2394',
      ),
      OrderSuggestionHelpersScenario(
        label: 'keeps move into minor province when at war (relation row present)',
        target: OrderSuggestionHelpersTarget.keepsMoveWhenAtWar,
        refs: '#2394',
      ),
      OrderSuggestionHelpersScenario(
        label: 'drops move into minor province when explicitly at peace',
        target: OrderSuggestionHelpersTarget.dropsMoveWhenAtPeace,
        refs: '#2394',
      ),
      OrderSuggestionHelpersScenario(
        label: 'keeps reordering-only move within own provinces',
        target: OrderSuggestionHelpersTarget.keepsReorderWithinOwnProvinces,
        refs: '#2394',
      ),
      OrderSuggestionHelpersScenario(
        label: 'keeps move into minor at peace when draft orders declare war',
        target: OrderSuggestionHelpersTarget.keepsMoveWhenDraftDeclaresWar,
        refs: '#2394',
      ),
    ];
