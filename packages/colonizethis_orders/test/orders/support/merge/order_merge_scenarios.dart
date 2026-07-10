// Table-driven mergeOrderLists scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_merge_run_rows.dart';

/// Canonical scenarios for [mergeOrderLists] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_merge_part*_test.dart` descriptions (single-line `label:` for CI).
List<RunnableScenario> orderMergeScenarios() => const [
  RunnableScenario(
    label: 'prefers human move orders over AI for same unit',
    run: omRunPrefersHumanMoveOverAi,
  ),
  RunnableScenario(
    label: 'keeps AI move orders when human has none for unit',
    run: omRunKeepsAiMoveWhenHumanNone,
  ),
  RunnableScenario(
    label: 'merges diplomatic orders with human precedence per (type,target)',
    run: omRunMergesDiplomaticHumanPrecedence,
  ),
  RunnableScenario(
    label: 'returns human orders when aiOrders is null',
    run: omRunReturnsHumanWhenAiNull,
  ),
  RunnableScenario(
    label: 'returns human orders when aiOrders is empty (all maps empty)',
    run: omRunReturnsHumanWhenAiEmpty,
  ),
  RunnableScenario(
    label: 'merge build orders: human and AI both contribute',
    run: omRunMergeBuildOrdersBothContribute,
  ),
  RunnableScenario(
    label: 'merge work orders: human for unit A, AI for unit B',
    run: omRunMergeWorkOrdersHumanAaiB,
  ),
  RunnableScenario(
    label: 'merge research orders: human wins when both have orders',
    run: omRunMergeResearchHumanWins,
  ),
  RunnableScenario(
    label: 'merge research orders: AI used when human has none',
    run: omRunMergeResearchAiWhenHumanNone,
  ),
  RunnableScenario(
    label: 'merge naval move orders: human and AI for different fleets',
    run: omRunMergeNavalMoveDifferentFleets,
  ),
  RunnableScenario(
    label: 'merge naval mission orders: human and AI for different fleets',
    run: omRunMergeNavalMissionDifferentFleets,
  ),
  RunnableScenario(
    label: 'multiple players: both get merged lists',
    run: omRunMultiplePlayersMergedLists,
  ),
  RunnableScenario(
    label: 'merges AI trade orders when human has none (Refs #2924)',
    run: omRunMergesAiTradeWhenHumanNone,
    refs: '#2924',
  ),
  RunnableScenario(
    label: 'human trade orders replace AI trade for same player',
    run: omRunHumanTradeReplacesAi,
  ),
  RunnableScenario(
    label: 'diplomatic merge drops AI order duplicating human (type,target)',
    run: omRunDiplomaticMergeDropsAiDuplicate,
  ),
  RunnableScenario(
    label: 'build merge appends AI after human, capped at combined count',
    run: omRunBuildMergeAppendsAiAfterHuman,
  ),
  RunnableScenario(
    label: 'merge uses stable player ordering',
    run: omRunMergeStablePlayerOrdering,
  ),
];
