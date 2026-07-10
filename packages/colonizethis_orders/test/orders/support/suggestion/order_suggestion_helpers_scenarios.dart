// Table-driven order suggestion helper scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_helpers_run_rows.dart';

/// One row in order suggestion helper scenario tables.
class OrderSuggestionHelpersScenario implements RefsScenario {
  const OrderSuggestionHelpersScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionHelpersScenario(
  OrderSuggestionHelpersScenario scenario,
) {
  scenario.run();
}

/// Scenarios for filterArmyMoveOrdersByDiplomacy.
List<OrderSuggestionHelpersScenario>
filterArmyMoveOrdersByDiplomacyScenarios() => const [
  OrderSuggestionHelpersScenario(
    label: 'drops move into minor-owned province when relation row is absent',
    run: oshRunDropsMoveWhenRelationAbsent,
    refs: '#2394',
  ),
  OrderSuggestionHelpersScenario(
    label: 'keeps move into minor province when at war (relation row present)',
    run: oshRunKeepsMoveWhenAtWar,
    refs: '#2394',
  ),
  OrderSuggestionHelpersScenario(
    label: 'drops move into minor province when explicitly at peace',
    run: oshRunDropsMoveWhenAtPeace,
    refs: '#2394',
  ),
  OrderSuggestionHelpersScenario(
    label: 'keeps reordering-only move within own provinces',
    run: oshRunKeepsReorderWithinOwnProvinces,
    refs: '#2394',
  ),
  OrderSuggestionHelpersScenario(
    label: 'keeps move into minor at peace when draft orders declare war',
    run: oshRunKeepsMoveWhenDraftDeclaresWar,
    refs: '#2394',
  ),
];
