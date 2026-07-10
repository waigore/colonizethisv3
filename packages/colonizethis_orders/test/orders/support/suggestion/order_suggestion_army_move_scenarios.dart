// Table-driven army-move suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_army_move_expectations.dart';

/// One row in [orderSuggestionArmyMoveScenarios].
class OrderSuggestionArmyMoveScenario implements RefsScenario {
  const OrderSuggestionArmyMoveScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionArmyMoveTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionArmyMoveScenario(
  OrderSuggestionArmyMoveScenario scenario,
) {
  runOrderSuggestionArmyMoveExpectation(scenario.target);
}

List<OrderSuggestionArmyMoveScenario> orderSuggestionArmyMoveScenarios() =>
    const [
      OrderSuggestionArmyMoveScenario(
        label: 'includes cross-region player-owned province as destination',
        target: OrderSuggestionArmyMoveTarget.includesCrossRegionOwnedDestination,
      ),
      OrderSuggestionArmyMoveScenario(
        label: 'armyMoveCandidateDestinationProvinceIds with PlayerView-owned cache matches legacy allProvinces scan',
        target:
            OrderSuggestionArmyMoveTarget.playerViewOwnedCacheMatchesLegacyScan,
      ),
      OrderSuggestionArmyMoveScenario(
        label: 'fallback owned-province scan derives its set from ProvinceOwnerCache (Phase 6b)',
        target:
            OrderSuggestionArmyMoveTarget.fallbackOwnedScanFromProvinceOwnerCache,
      ),
      OrderSuggestionArmyMoveScenario(
        label: 'fallback yields no owned destinations when ProvinceOwnerCache has none for the player (Phase 6b negative)',
        target:
            OrderSuggestionArmyMoveTarget.fallbackNoOwnedWhenCacheEmptyForPlayer,
      ),
      OrderSuggestionArmyMoveScenario(
        label: 'still proposes alternate destination when draft has prior army move',
        target:
            OrderSuggestionArmyMoveTarget.stillProposesAlternateWhenDraftHasPriorMove,
      ),
    ];

List<OrderSuggestionArmyMoveScenario>
    orderSuggestionArmyMoveDestIdsScenarios() => const [
          OrderSuggestionArmyMoveScenario(
            label: 'cached player-owned set matches default allProvinces scan',
            target: OrderSuggestionArmyMoveTarget
                .cachedOwnedSetMatchesDefaultAllProvincesScan,
          ),
        ];
