// Table-driven work-tile-keys shared-validator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_keys_shared_validator_run_rows.dart';

/// One row in [orderSuggestionWorkTileKeysSharedValidatorScenarios].
class OrderSuggestionWorkTileKeysSharedValidatorScenario
    implements RefsScenario {
  const OrderSuggestionWorkTileKeysSharedValidatorScenario({
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

void runOrderSuggestionWorkTileKeysSharedValidatorScenario(
  OrderSuggestionWorkTileKeysSharedValidatorScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionWorkTileKeysSharedValidatorScenario>
orderSuggestionWorkTileKeysSharedValidatorVisibilityScenarios() => const [
  OrderSuggestionWorkTileKeysSharedValidatorScenario(
    label: 'sharedCandidateValidator matches default path for same inputs',
    run: oswtkRunSharedCandidateValidatorMatchesDefaultPath,
  ),
  OrderSuggestionWorkTileKeysSharedValidatorScenario(
    label: 'playerOwnedProvinceIds matches default path for same inputs',
    run: oswtkRunPlayerOwnedProvinceIdsMatchesDefaultPath,
  ),
  OrderSuggestionWorkTileKeysSharedValidatorScenario(
    label: 'optional unitsById matches default path',
    run: oswtkRunOptionalUnitsByIdMatchesDefaultPath,
  ),
];

List<OrderSuggestionWorkTileKeysSharedValidatorScenario>
orderSuggestionWorkTileKeysSharedValidatorPlayerViewScenarios() => const [
  OrderSuggestionWorkTileKeysSharedValidatorScenario(
    label: 'matches prior behavior for builder improvement tiles',
    run: oswtkRunMatchesPriorBehaviorForBuilderImprovementTiles,
  ),
  OrderSuggestionWorkTileKeysSharedValidatorScenario(
    label: 'shared view and validator matches default path',
    run: oswtkRunSharedViewAndValidatorMatchesDefaultPath,
  ),
];
