// Table-driven draft-order mutation scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'draft_orders_mutations_expectations.dart';

/// One row in draft-order mutation scenario tables.
class DraftOrdersMutationsScenario implements RefsScenario {
  const DraftOrdersMutationsScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DraftOrdersMutationsTarget target;
  @override
  final String? refs;
}

void runDraftOrdersMutationsScenario(DraftOrdersMutationsScenario scenario) {
  runDraftOrdersMutationsExpectation(scenario.target);
}

/// Scenarios for removePendingWorkOrderAt.
List<DraftOrdersMutationsScenario> removePendingWorkOrderAtScenarios() =>
    const [
      DraftOrdersMutationsScenario(
        label: 'removes order at index',
        target: DraftOrdersMutationsTarget.removePendingWorkOrderAtRemovesAtIndex,
      ),
      DraftOrdersMutationsScenario(
        label: 'returns orders unchanged when index invalid',
        target:
            DraftOrdersMutationsTarget.removePendingWorkOrderAtInvalidIndexNoOp,
      ),
    ];

/// Scenarios for trade-order draft helpers (Refs #2993 E5b).
List<DraftOrdersMutationsScenario> draftOrdersTradeMutationScenarios() =>
    const [
      DraftOrdersMutationsScenario(
        label: 'tradeOrderForPlayerCommodity returns null on empty orders',
        target: DraftOrdersMutationsTarget.tradeOrderForPlayerCommodityEmpty,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'tradeOrderForPlayerCommodity returns the matching staged order',
        target: DraftOrdersMutationsTarget.tradeOrderForPlayerCommodityMatching,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label: 'applyTradeOrderForPlayer adds when no prior order exists',
        target: DraftOrdersMutationsTarget.applyTradeOrderForPlayerAdds,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'applyTradeOrderForPlayer replaces a prior order for the same '
            'commodity (mutual exclusion: bid -> offer cannot coexist)',
        target:
            DraftOrdersMutationsTarget.applyTradeOrderForPlayerReplacesMutualExclusion,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'applyTradeOrderForPlayer scopes per-player (other players\' '
            'orders are not affected)',
        target: DraftOrdersMutationsTarget.applyTradeOrderForPlayerScopesPerPlayer,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label: 'removeTradeOrderForPlayer deletes the matching staged order',
        target: DraftOrdersMutationsTarget.removeTradeOrderForPlayerDeletes,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'removeTradeOrderForPlayer is a no-op (returns same instance) when '
            'the player has no staged orders',
        target: DraftOrdersMutationsTarget.removeTradeOrderForPlayerNoOpEmpty,
        refs: '#2993 E5b',
      ),
      DraftOrdersMutationsScenario(
        label:
            'removeTradeOrderForPlayer is a no-op (returns same instance) when '
            'the commodity is not present in the staged list',
        target:
            DraftOrdersMutationsTarget.removeTradeOrderForPlayerNoOpMissingCommodity,
        refs: '#2993 E5b',
      ),
    ];
