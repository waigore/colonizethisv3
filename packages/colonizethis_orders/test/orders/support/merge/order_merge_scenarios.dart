// Table-driven mergeOrderLists scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_merge_run_rows.dart';

/// One row in [orderMergeScenarios].
class OrderMergeScenario implements RefsScenario {
  const OrderMergeScenario({required this.label, required this.run, this.refs});

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderMergeScenario(OrderMergeScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [mergeOrderLists] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_merge_part*_test.dart` descriptions (single-line `label:` for CI).
List<OrderMergeScenario> orderMergeScenarios() => const [
  OrderMergeScenario(
    label: 'prefers human move orders over AI for same unit',
    run: omRunPrefersHumanMoveOverAi,
  ),
  OrderMergeScenario(
    label: 'keeps AI move orders when human has none for unit',
    run: omRunKeepsAiMoveWhenHumanNone,
  ),
  OrderMergeScenario(
    label: 'merges diplomatic orders with human precedence per (type,target)',
    run: omRunMergesDiplomaticHumanPrecedence,
  ),
  OrderMergeScenario(
    label: 'returns human orders when aiOrders is null',
    run: omRunReturnsHumanWhenAiNull,
  ),
  OrderMergeScenario(
    label: 'returns human orders when aiOrders is empty (all maps empty)',
    run: omRunReturnsHumanWhenAiEmpty,
  ),
  OrderMergeScenario(
    label: 'merge build orders: human and AI both contribute',
    run: omRunMergeBuildOrdersBothContribute,
  ),
  OrderMergeScenario(
    label: 'merge work orders: human for unit A, AI for unit B',
    run: omRunMergeWorkOrdersHumanAaiB,
  ),
  OrderMergeScenario(
    label: 'merge research orders: human wins when both have orders',
    run: omRunMergeResearchHumanWins,
  ),
  OrderMergeScenario(
    label: 'merge research orders: AI used when human has none',
    run: omRunMergeResearchAiWhenHumanNone,
  ),
  OrderMergeScenario(
    label: 'merge naval move orders: human and AI for different fleets',
    run: omRunMergeNavalMoveDifferentFleets,
  ),
  OrderMergeScenario(
    label: 'merge naval mission orders: human and AI for different fleets',
    run: omRunMergeNavalMissionDifferentFleets,
  ),
  OrderMergeScenario(
    label: 'multiple players: both get merged lists',
    run: omRunMultiplePlayersMergedLists,
  ),
  OrderMergeScenario(
    label: 'merges AI trade orders when human has none (Refs #2924)',
    run: omRunMergesAiTradeWhenHumanNone,
    refs: '#2924',
  ),
  OrderMergeScenario(
    label: 'human trade orders replace AI trade for same player',
    run: omRunHumanTradeReplacesAi,
  ),
  OrderMergeScenario(
    label: 'diplomatic merge drops AI order duplicating human (type,target)',
    run: omRunDiplomaticMergeDropsAiDuplicate,
  ),
  OrderMergeScenario(
    label: 'build merge appends AI after human, capped at combined count',
    run: omRunBuildMergeAppendsAiAfterHuman,
  ),
  OrderMergeScenario(
    label: 'merge uses stable player ordering',
    run: omRunMergeStablePlayerOrdering,
  ),
];
