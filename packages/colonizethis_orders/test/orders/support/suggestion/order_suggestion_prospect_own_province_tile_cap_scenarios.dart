// Table-driven own-province prospect tile-cap scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_own_province_tile_cap_run_rows.dart';

class OrderSuggestionProspectOwnProvinceTileCapScenario
    implements LabeledScenario {
  const OrderSuggestionProspectOwnProvinceTileCapScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionProspectOwnProvinceTileCapScenario(
  OrderSuggestionProspectOwnProvinceTileCapScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionProspectOwnProvinceTileCapScenario>
orderSuggestionProspectOwnProvinceTileCapScenarios() => const [
  OrderSuggestionProspectOwnProvinceTileCapScenario(
    label:
        'co-located Explorer still prospects feedstock iron when it sorts after four other accepted mineral tiles in the same province',
    run: ospoptcRunFeedstockPastProbeCap,
  ),
];
