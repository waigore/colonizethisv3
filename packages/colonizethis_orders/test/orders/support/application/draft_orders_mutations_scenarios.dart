// Table-driven draft-order mutation scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'draft_orders_mutations_run_rows.dart';

/// One row in draft-order mutation scenario tables.
class DraftOrdersMutationsScenario implements RefsScenario {
  const DraftOrdersMutationsScenario({
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

void runDraftOrdersMutationsScenario(DraftOrdersMutationsScenario scenario) {
  scenario.run();
}

/// Scenarios for removePendingWorkOrderAt.
List<DraftOrdersMutationsScenario> removePendingWorkOrderAtScenarios() =>
    const [
      DraftOrdersMutationsScenario(
        label: 'removes order at index',
        run: domRunRemovePendingWorkOrderAtRemovesAtIndex,
      ),
      DraftOrdersMutationsScenario(
        label: 'returns orders unchanged when index invalid',
        run: domRunRemovePendingWorkOrderAtInvalidIndexNoOp,
      ),
    ];

/// Scenarios for trade-order draft helpers (Refs #2993 E5b).
List<DraftOrdersMutationsScenario> draftOrdersTradeMutationScenarios() =>
    const [
      DraftOrdersMutationsScenario(
        label: 'tradeOrderForPlayerCommodity returns null on empty orders',
        run: domRunTradeOrderForPlayerCommodityEmpty,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'tradeOrderForPlayerCommodity returns the matching staged order',
        run: domRunTradeOrderForPlayerCommodityMatching,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label: 'applyTradeOrderForPlayer adds when no prior order exists',
        run: domRunApplyTradeOrderForPlayerAdds,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'applyTradeOrderForPlayer replaces a prior order for the same '
            'commodity (mutual exclusion: bid -> offer cannot coexist)',
        run: domRunApplyTradeOrderForPlayerReplacesMutualExclusion,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'applyTradeOrderForPlayer scopes per-player (other players\' '
            'orders are not affected)',
        run: domRunApplyTradeOrderForPlayerScopesPerPlayer,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label: 'removeTradeOrderForPlayer deletes the matching staged order',
        run: domRunRemoveTradeOrderForPlayerDeletes,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'removeTradeOrderForPlayer is a no-op (returns same instance) when '
            'the player has no staged orders',
        run: domRunRemoveTradeOrderForPlayerNoOpEmpty,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'removeTradeOrderForPlayer is a no-op (returns same instance) when '
            'the commodity is not present in the staged list',
        run: domRunRemoveTradeOrderForPlayerNoOpMissingCommodity,
        refs: '#2993 E5b',
      ),
    ];
