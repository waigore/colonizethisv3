// Table-driven work-tile-keys shared-validator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_keys_shared_validator_expectations.dart';

/// One row in [orderSuggestionWorkTileKeysSharedValidatorScenarios].
class OrderSuggestionWorkTileKeysSharedValidatorScenario
    implements RefsScenario {
  const OrderSuggestionWorkTileKeysSharedValidatorScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionWorkTileKeysSharedValidatorTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionWorkTileKeysSharedValidatorScenario(
  OrderSuggestionWorkTileKeysSharedValidatorScenario scenario,
) {
  runOrderSuggestionWorkTileKeysSharedValidatorExpectation(scenario.target);
}

List<OrderSuggestionWorkTileKeysSharedValidatorScenario>
    orderSuggestionWorkTileKeysSharedValidatorVisibilityScenarios() =>
        const [
          OrderSuggestionWorkTileKeysSharedValidatorScenario(
            label: 'sharedCandidateValidator matches default path for same inputs',
            target: OrderSuggestionWorkTileKeysSharedValidatorTarget
                .sharedCandidateValidatorMatchesDefaultPath,
          ),
          OrderSuggestionWorkTileKeysSharedValidatorScenario(
            label: 'playerOwnedProvinceIds matches default path for same inputs',
            target: OrderSuggestionWorkTileKeysSharedValidatorTarget
                .playerOwnedProvinceIdsMatchesDefaultPath,
          ),
          OrderSuggestionWorkTileKeysSharedValidatorScenario(
            label: 'optional unitsById matches default path',
            target: OrderSuggestionWorkTileKeysSharedValidatorTarget
                .optionalUnitsByIdMatchesDefaultPath,
          ),
        ];

List<OrderSuggestionWorkTileKeysSharedValidatorScenario>
    orderSuggestionWorkTileKeysSharedValidatorPlayerViewScenarios() =>
        const [
          OrderSuggestionWorkTileKeysSharedValidatorScenario(
            label: 'matches prior behavior for builder improvement tiles',
            target: OrderSuggestionWorkTileKeysSharedValidatorTarget
                .matchesPriorBehaviorForBuilderImprovementTiles,
          ),
          OrderSuggestionWorkTileKeysSharedValidatorScenario(
            label: 'shared view and validator matches default path',
            target: OrderSuggestionWorkTileKeysSharedValidatorTarget
                .sharedViewAndValidatorMatchesDefaultPath,
          ),
        ];
