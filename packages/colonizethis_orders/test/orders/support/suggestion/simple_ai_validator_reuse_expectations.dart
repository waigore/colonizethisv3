// Simple-AI validator-reuse assertions (Refs #2394, #3949 wave 3).

import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';

import 'simple_ai_validator_reuse_fixtures.dart';

/// Pins for [simpleAiValidatorReuseScenarios] rows.
enum SimpleAiValidatorReuseTarget {
  oneValidatorPerHeuristicPass,
  oneValidatorPerAiPlayerBatch,
}

void runSimpleAiValidatorReuseExpectation(SimpleAiValidatorReuseTarget target) {
  switch (target) {
    case SimpleAiValidatorReuseTarget.oneValidatorPerHeuristicPass:
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

    case SimpleAiValidatorReuseTarget.oneValidatorPerAiPlayerBatch:
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
}
