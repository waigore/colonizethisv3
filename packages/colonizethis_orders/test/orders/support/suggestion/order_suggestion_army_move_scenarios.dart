// Table-driven army-move suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_run_rows.dart';

/// One row in [orderSuggestionArmyMoveScenarios].
class OrderSuggestionArmyMoveScenario implements RefsScenario {
  const OrderSuggestionArmyMoveScenario({
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

void runOrderSuggestionArmyMoveScenario(
  OrderSuggestionArmyMoveScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionArmyMoveScenario>
orderSuggestionArmyMoveScenarios() => const [
  OrderSuggestionArmyMoveScenario(
    label: 'includes cross-region player-owned province as destination',
    run: osamRunIncludesCrossRegionOwnedDestination,
  ),
  OrderSuggestionArmyMoveScenario(
    label:
        'armyMoveCandidateDestinationProvinceIds with PlayerView-owned cache matches legacy allProvinces scan',
    run: osamRunPlayerViewOwnedCacheMatchesLegacyScan,
  ),
  OrderSuggestionArmyMoveScenario(
    label:
        'fallback owned-province scan derives its set from ProvinceOwnerCache (Phase 6b)',
    run: osamRunFallbackOwnedScanFromProvinceOwnerCache,
  ),
  OrderSuggestionArmyMoveScenario(
    label:
        'fallback yields no owned destinations when ProvinceOwnerCache has none for the player (Phase 6b negative)',
    run: osamRunFallbackNoOwnedWhenCacheEmptyForPlayer,
  ),
  OrderSuggestionArmyMoveScenario(
    label:
        'still proposes alternate destination when draft has prior army move',
    run: osamRunStillProposesAlternateWhenDraftHasPriorMove,
  ),
];

List<OrderSuggestionArmyMoveScenario>
orderSuggestionArmyMoveDestIdsScenarios() => const [
  OrderSuggestionArmyMoveScenario(
    label: 'cached player-owned set matches default allProvinces scan',
    run: osamRunCachedOwnedSetMatchesDefaultAllProvincesScan,
  ),
];
