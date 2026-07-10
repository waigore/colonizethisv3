// Table-driven mergeOrderLists scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_merge_expectations.dart';

/// One row in [orderMergeScenarios].
class OrderMergeScenario implements RefsScenario {
  const OrderMergeScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderMergeTarget target;
  @override
  final String? refs;
}

void runOrderMergeScenario(OrderMergeScenario scenario) {
  runOrderMergeExpectation(scenario.target);
}

/// Canonical scenarios for [mergeOrderLists] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_merge_part*_test.dart` descriptions (single-line `label:` for CI).
List<OrderMergeScenario> orderMergeScenarios() => const [
      OrderMergeScenario(
        label: 'prefers human move orders over AI for same unit',
        target: OrderMergeTarget.prefersHumanMoveOverAi,
      ),
      OrderMergeScenario(
        label: 'keeps AI move orders when human has none for unit',
        target: OrderMergeTarget.keepsAiMoveWhenHumanNone,
      ),
      OrderMergeScenario(
        label: 'merges diplomatic orders with human precedence per (type,target)',
        target: OrderMergeTarget.mergesDiplomaticHumanPrecedence,
      ),
      OrderMergeScenario(
        label: 'returns human orders when aiOrders is null',
        target: OrderMergeTarget.returnsHumanWhenAiNull,
      ),
      OrderMergeScenario(
        label: 'returns human orders when aiOrders is empty (all maps empty)',
        target: OrderMergeTarget.returnsHumanWhenAiEmpty,
      ),
      OrderMergeScenario(
        label: 'merge build orders: human and AI both contribute',
        target: OrderMergeTarget.mergeBuildOrdersBothContribute,
      ),
      OrderMergeScenario(
        label: 'merge work orders: human for unit A, AI for unit B',
        target: OrderMergeTarget.mergeWorkOrdersHumanAaiB,
      ),
      OrderMergeScenario(
        label: 'merge research orders: human wins when both have orders',
        target: OrderMergeTarget.mergeResearchHumanWins,
      ),
      OrderMergeScenario(
        label: 'merge research orders: AI used when human has none',
        target: OrderMergeTarget.mergeResearchAiWhenHumanNone,
      ),
      OrderMergeScenario(
        label: 'merge naval move orders: human and AI for different fleets',
        target: OrderMergeTarget.mergeNavalMoveDifferentFleets,
      ),
      OrderMergeScenario(
        label: 'merge naval mission orders: human and AI for different fleets',
        target: OrderMergeTarget.mergeNavalMissionDifferentFleets,
      ),
      OrderMergeScenario(
        label: 'multiple players: both get merged lists',
        target: OrderMergeTarget.multiplePlayersMergedLists,
      ),
      OrderMergeScenario(
        label: 'merges AI trade orders when human has none (Refs #2924)',
        target: OrderMergeTarget.mergesAiTradeWhenHumanNone,
        refs: '#2924',
      ),
      OrderMergeScenario(
        label: 'human trade orders replace AI trade for same player',
        target: OrderMergeTarget.humanTradeReplacesAi,
      ),
      OrderMergeScenario(
        label: 'diplomatic merge drops AI order duplicating human (type,target)',
        target: OrderMergeTarget.diplomaticMergeDropsAiDuplicate,
      ),
      OrderMergeScenario(
        label: 'build merge appends AI after human, capped at combined count',
        target: OrderMergeTarget.buildMergeAppendsAiAfterHuman,
      ),
      OrderMergeScenario(
        label: 'merge uses stable player ordering',
        target: OrderMergeTarget.mergeStablePlayerOrdering,
      ),
    ];
