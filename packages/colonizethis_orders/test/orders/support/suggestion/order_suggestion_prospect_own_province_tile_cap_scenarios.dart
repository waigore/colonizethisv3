// Table-driven own-province prospect tile-cap scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_own_province_tile_cap_expectations.dart';

class OrderSuggestionProspectOwnProvinceTileCapScenario
    implements LabeledScenario {
  const OrderSuggestionProspectOwnProvinceTileCapScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderSuggestionProspectOwnProvinceTileCapTarget target;
}

void runOrderSuggestionProspectOwnProvinceTileCapScenario(
  OrderSuggestionProspectOwnProvinceTileCapScenario scenario,
) {
  runOrderSuggestionProspectOwnProvinceTileCapExpectation(scenario.target);
}

List<OrderSuggestionProspectOwnProvinceTileCapScenario>
    orderSuggestionProspectOwnProvinceTileCapScenarios() => const [
          OrderSuggestionProspectOwnProvinceTileCapScenario(
            label: 'co-located Explorer still prospects feedstock iron when it sorts after four other accepted mineral tiles in the same province',
            target: OrderSuggestionProspectOwnProvinceTileCapTarget
                .feedstockPastProbeCap,
          ),
        ];
