// Table-driven simple-AI validator-reuse scenarios (Refs #3949 wave 3).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'simple_ai_validator_reuse_fixtures.dart';

void savrRunOneValidatorPerHeuristicPass() {
  final game = simpleAiValidatorReuseTwoGpWarGame();
  resetIncrementalCandidateValidatorBuildCountForTests();
  generateOrdersWithSimpleHeuristics(
    game,
    simpleAiValidatorReuseTopology,
    'gp1',
    turnSeedForPlayer(game, 'gp1', 1),
  );
  expect(
    incrementalCandidateValidatorBuildCountForTests,
    1,
    reason:
        'one pass-level build; iterations must rebind via forBasePrefix '
        'without rebuild (Refs #2394)',
  );
}

void savrRunOneValidatorPerAiPlayerBatch() {
  final game = simpleAiValidatorReuseTwoGpWarGame();
  resetIncrementalCandidateValidatorBuildCountForTests();
  generateOrdersForGame(game, simpleAiValidatorReuseTopology);
  expect(
    incrementalCandidateValidatorBuildCountForTests,
    2,
    reason:
        'one pass-level build per AI GP; must not rebuild per iteration '
        'or suggestion family (Refs #2394)',
  );
}

List<RunnableScenario> simpleAiValidatorReuseHeuristicScenarios() => const [
  rs('builds one incremental validator per player heuristic pass', savrRunOneValidatorPerHeuristicPass, '#2394'),
];

List<RunnableScenario> simpleAiValidatorReuseBatchScenarios() => const [
  rs('builds one incremental validator per AI player in batch path', savrRunOneValidatorPerAiPlayerBatch, '#2394'),
];
